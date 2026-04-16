defmodule MailgunLoggerWeb.UserController do
  alias MailgunLogger.Roles
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Users
  alias MailgunLogger.User

  def index(conn, _) do
    users = Users.list_users()
    render(conn, :index, users: users)
  end

  def new(conn, _) do
    changeset = User.changeset(%User{})
    assignable_roles = Roles.assignable_roles()
    render(conn, :new, changeset: changeset, assignable_roles: assignable_roles)
  end

  def create(conn, %{"user" => params}) do
    case Users.create_user(params) do
      {:ok, _} -> redirect(conn, to: Routes.user_path(conn, :index))
      {:error, changeset} -> render(conn, :new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    changeset = User.changeset(user)

    render(conn, :edit,
      changeset: changeset,
      user: user,
      assignable_roles: Roles.assignable_roles(),
      editable_roles: Roles.can_modify_roles?(conn.assigns.current_user, user)
    )
  end

  def update(conn, %{"id" => id, "user" => params}) do
    # A user should be able to update a target user if it's
    user = Users.get_user!(id)

    case Users.update_user(user, params) do
      {:ok, _} ->
        redirect(conn, to: Routes.user_path(conn, :index))

      {:error, changeset} ->
        render(conn, :edit,
          changeset: changeset,
          user: user,
          assignable_roles: Roles.assignable_roles(),
          editable_roles: Roles.can_modify_roles?(conn.assigns.current_user, user)
        )
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
