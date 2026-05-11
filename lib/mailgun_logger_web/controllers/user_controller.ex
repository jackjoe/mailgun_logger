defmodule MailgunLoggerWeb.UserController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Users
  alias MailgunLogger.User
  alias MailgunLogger.Roles

  defp role_options do
    MailgunLogger.Roles.list_roles()
    |> Enum.map(fn role ->
      {String.capitalize(role.name), role.id}
    end)
  end

  def index(conn, _) do
    users = Users.list_users()
    render(conn, :index, users: users)
  end

  def new(conn, _) do
    changeset = User.changeset(%User{})
    render(conn, :new, changeset: changeset, roles: role_options())
  end

  def create(conn, %{"user" => params}) do
    roles =
      params
      |> Map.get("role_ids", [])
      |> Roles.get_roles_by_id()

    case Users.create_user(params, roles) do
      {:ok, _} -> redirect(conn, to: Routes.user_path(conn, :index))
      {:error, changeset} -> render(conn, :new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    changeset = User.changeset(user)
    current_user = conn.assigns.current_user
    is_self = current_user.id == user.id
    render(conn, :edit, changeset: changeset, user: user, roles: role_options(), is_self: is_self)
  end

  def update(conn, %{"id" => id, "user" => params}) do
    user = Users.get_user!(id)

    roles =
      params
      |> Map.get("role_ids", [])
      |> Roles.get_roles_by_id()

    case Users.update_user(user, params, roles) do
      {:ok, _} ->
        redirect(conn, to: Routes.user_path(conn, :index))

      {:error, changeset} ->
        render(conn, :edit, changeset: changeset, user: user, roles: role_options())
    end
  end

  def delete(conn, %{"id" => id}) do
    {:ok, _} =
      id
      |> Users.get_user!()
      |> Users.delete_user()

    conn
    |> put_flash(:info, "user deleted successfully.")
    |> redirect(to: Routes.user_path(conn, :index))
  end
end
