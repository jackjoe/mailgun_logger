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

    if can_manage?(conn.assigns.current_user, user) do
      current_role_id =
        case user.roles do
          [%{id: id} | _] -> id
          _ -> nil
        end

      changeset =
        user
        |> User.changeset()
        |> Ecto.Changeset.put_change(:role_id, current_role_id)

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
      not can_manage?(actor, user) ->
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

      not can_manage?(actor, user) ->
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

  # Only superusers can manage other superusers. Admins can manage admins/members.
  defp can_manage?(actor, target) do
    Roles.is?(actor, :superuser) or not Roles.is?(target, :superuser)
  end

  # Admins cannot grant the `superuser` role; drop it from incoming params.
  defp sanitize_role_params(actor, %{"role_id" => id} = params) when id not in [nil, ""] do
    if Roles.is?(actor, :superuser) do
      params
    else
      superuser_id = to_string(Roles.get_role_by_name("superuser").id)

      if to_string(id) == superuser_id do
        Map.delete(params, "role_id")
      else
        params
      end
    end
  end

  defp sanitize_role_params(_actor, params), do: params

  defp changing_own_role?(actor, target, %{"role_id" => new_id})
       when new_id not in [nil, ""] do
    if actor.id == target.id do
      current_ids = Enum.map(target.roles, &to_string(&1.id))
      to_string(new_id) not in current_ids
    else
      false
    end
  end

  defp changing_own_role?(_actor, _target, _params), do: false

  defp demoting_last_superuser?(target, %{"role_id" => new_id})
       when new_id not in [nil, ""] do
    target_is_superuser = Enum.any?(target.roles, &(&1.name == "superuser"))
    superuser_id = to_string(Roles.get_role_by_name("superuser").id)
    still_superuser = to_string(new_id) == superuser_id

    target_is_superuser and not still_superuser and Users.count_superusers() <= 1
  end

  defp demoting_last_superuser?(_target, _params), do: false
end
