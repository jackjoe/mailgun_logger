defmodule MailgunLoggerWeb.UserController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Roles
  alias MailgunLogger.Users
  alias MailgunLogger.User

  def index(conn, _) do
    users = Users.list_users()
    render(conn, :index, users: users)
  end

  def new(conn, _) do
    current_user = conn.assigns[:current_user]
    changeset = User.changeset(%User{})

    render(conn, :new,
      changeset: changeset,
      all_roles: Roles.list_roles(),
      selected_role_ids: [],
      show_roles?: Roles.can?(current_user, :manage_roles)
    )
  end

  def create(conn, %{"user" => params}) do
    current_user = conn.assigns[:current_user]
    roles = resolve_roles(current_user, params, [])

    case Users.create_user_with_roles(params, roles) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: Routes.user_path(conn, :index))

      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          all_roles: Roles.list_roles(),
          selected_role_ids: Enum.map(roles, & &1.id),
          show_roles?: Roles.can?(current_user, :manage_roles)
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    current_user = conn.assigns[:current_user]
    user = Users.get_user!(id)
    changeset = User.update_changeset(user)

    render(conn, :edit,
      changeset: changeset,
      user: user,
      all_roles: Roles.list_roles(),
      selected_role_ids: Enum.map(user.roles, & &1.id),
      show_roles?: Roles.can?(current_user, :manage_roles)
    )
  end

  def update(conn, %{"id" => id, "user" => params}) do
    current_user = conn.assigns[:current_user]
    user = Users.get_user!(id)
    roles = resolve_roles(current_user, params, user.roles)

    if Roles.can?(current_user, :manage_roles) && current_user.id == user.id &&
         self_downgrade?(current_user, roles) do
      conn
      |> put_flash(:error, "You cannot remove your own role.")
      |> render(:edit,
        changeset: User.update_changeset(user, params),
        user: user,
        all_roles: Roles.list_roles(),
        selected_role_ids: Enum.map(roles, & &1.id),
        show_roles?: true
      )
    else
      case Users.update_user_with_roles(user, params, roles) do
        {:ok, _updated} ->
          conn
          |> put_flash(:info, "User updated successfully.")
          |> redirect(to: Routes.user_path(conn, :index))

        {:error, changeset} ->
          render(conn, :edit,
            changeset: changeset,
            user: user,
            all_roles: Roles.list_roles(),
            selected_role_ids: Enum.map(roles, & &1.id),
            show_roles?: Roles.can?(current_user, :manage_roles)
          )
      end
    end
  end

  def delete(conn, %{"id" => id}) do
    {:ok, _} = id |> Users.get_user!() |> Users.delete_user()

    conn
    |> put_flash(:info, "user deleted successfully.")
    |> redirect(to: Routes.user_path(conn, :index))
  end

  defp resolve_roles(current_user, params, existing_roles) do
    if Roles.can?(current_user, :manage_roles) do
      params |> Map.get("role_ids", []) |> Enum.map(&String.to_integer/1) |> Roles.get_roles_by_id()
    else
      existing_roles
    end
  end

  defp self_downgrade?(%User{roles: current_roles}, new_roles) do
    current_ids = MapSet.new(current_roles, & &1.id)
    new_ids = MapSet.new(new_roles, & &1.id)
    not MapSet.subset?(current_ids, new_ids)
  end
end
