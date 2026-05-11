defmodule MailgunLoggerWeb.UserController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Users
  alias MailgunLogger.User
  alias MailgunLogger.Roles

  plug Authorize

  @action_permissions %{
    index: :view_users,
    new: :create_user,
    create: :create_user,
    edit: :edit_user,
    update: :edit_user,
    delete: :delete_user
  }

  def action_permissions, do: @action_permissions

  def index(conn, _) do
    users = Users.list_users()
    render(conn, :index, users: users)
  end

  def new(conn, _) do
    changeset = User.changeset(%User{})
    render(conn, :new, changeset: changeset, roles: role_options())
  end

  def create(conn, %{"user" => params}) do
    # Check if the users has the permission to grant specific role
    params = sanitize_role_params(conn.assigns.current_user, params)

    case Users.create_user(params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "User created.")
        |> redirect(to: Routes.user_path(conn, :index))

      {:error, changeset} ->
        render(conn, :new, changeset: changeset, roles: role_options())
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    actor = conn.assigns.current_user

    # Check if the current user can manage the target user same rank of permissions
    if Roles.can_manage?(actor, user) do
      current_role_ids = Enum.map(user.roles, & &1.id)

      changeset =
        user
        |> User.changeset()
        |> Ecto.Changeset.put_change(:role_ids, current_role_ids)

      render(conn, :edit, changeset: changeset, user: user, roles: role_options())
    else
      conn
      |> put_flash(:error, "You cannot edit this user.")
      |> redirect(to: Routes.user_path(conn, :index))
    end
  end

  def update(conn, %{"id" => id, "user" => params}) do
    user = Users.get_user!(id)
    actor = conn.assigns.current_user

    cond do
      not Roles.can_manage?(actor, user) ->
        conn
        |> put_flash(:error, "You cannot edit this user.")
        |> redirect(to: Routes.user_path(conn, :index))

      changing_own_role?(actor, user, params) ->
        conn
        |> put_flash(:error, "You cannot change your own role.")
        |> redirect(to: Routes.user_path(conn, :edit, user))

      demoting_last_superuser?(user, params) ->
        conn
        |> put_flash(:error, "Cannot remove the last superuser.")
        |> redirect(to: Routes.user_path(conn, :edit, user))

      true ->
        params = sanitize_role_params(actor, params)

        case Users.update_user(user, params) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "User updated.")
            |> redirect(to: Routes.user_path(conn, :index))

          {:error, changeset} ->
            render(conn, :edit, changeset: changeset, user: user, roles: role_options())
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    actor = conn.assigns.current_user

    cond do
      actor.id == user.id ->
        conn
        |> put_flash(:error, "You cannot delete your own account.")
        |> redirect(to: Routes.user_path(conn, :index))

      not Roles.can_manage?(actor, user) ->
        conn
        |> put_flash(:error, "You cannot delete this user.")
        |> redirect(to: Routes.user_path(conn, :index))

      Roles.is?(user, :superuser) and Users.count_superusers() <= 1 ->
        conn
        |> put_flash(:error, "Cannot delete the last superuser.")
        |> redirect(to: Routes.user_path(conn, :index))

      true ->
        {:ok, _} = Users.delete_user(user)

        conn
        |> put_flash(:info, "User deleted successfully.")
        |> redirect(to: Routes.user_path(conn, :index))
    end
  end

  # Roles as `{label, value}` tuples for the role dropdown.
  defp role_options do
    Roles.list_roles() |> Enum.map(&{&1.name, &1.id})
  end

  # Keep only the role IDs the actor is allowed to grant.
  defp sanitize_role_params(actor, %{"role_ids" => ids} = params) when is_list(ids) do
    allowed_ids =
      ids
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Roles.get_roles_by_id()
      |> Enum.filter(&Roles.can_grant_role?(actor, &1.name))
      |> Enum.map(&to_string(&1.id))

    Map.put(params, "role_ids", allowed_ids)
  end

  defp sanitize_role_params(_actor, params), do: params

  defp changing_own_role?(actor, target, %{"role_ids" => ids}) when is_list(ids) do
    if actor.id == target.id do
      current = target.roles |> Enum.map(&to_string(&1.id)) |> Enum.sort()
      incoming = ids |> Enum.reject(&(&1 in [nil, ""])) |> Enum.sort()
      current != incoming
    else
      false
    end
  end

  defp changing_own_role?(_actor, _target, _params), do: false

  defp demoting_last_superuser?(target, %{"role_ids" => ids}) when is_list(ids) do
    target_is_superuser = Enum.any?(target.roles, &(&1.name == "superuser"))
    superuser_id = to_string(Roles.get_role_by_name("superuser").id)
    still_superuser = superuser_id in ids

    target_is_superuser and not still_superuser and Users.count_superusers() <= 1
  end

  defp demoting_last_superuser?(_target, _params), do: false
end
