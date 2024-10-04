defmodule MailgunLoggerWeb.UserController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Users
  alias MailgunLogger.User
  alias MailgunLogger.Roles

  plug(:authorize)

  defp authorize(conn, _options) do
    action = Phoenix.Controller.action_name(conn)
    current_user = conn.assigns.current_user

    if Roles.can?(current_user, action, User) do
      conn
    else
      conn |> resp(403, []) |> halt()
    end
  end

  def index(conn, _) do
    users = Users.list_users()
    render(conn, :index, users: users)
  end

  def new(conn, _) do
    changeset =
      User.changeset(%User{
        roles: [
          # Default role for new users
          Roles.get_role_by_name("member")
        ]
      })

    render(conn, :new,
      changeset: changeset,
      all_role_names: Roles.get_assignable_role_names()
    )
  end

  def create(conn, %{"user" => _user_params} = params) do
    user_params = Roles.add_form_roles_to_user_params(params)

    case Users.create_user(user_params) do
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
      all_role_names: Roles.get_assignable_role_names()
    )
  end

  def update(conn, %{"id" => id, "user" => _user_params} = params) do
    existing_user = Users.get_user!(id)

    user_params = Roles.add_form_roles_to_user_params(params)

    case Users.update_user(existing_user, user_params) do
      {:ok, _} ->
        redirect(conn, to: Routes.user_path(conn, :index))

      {:error, changeset} ->
        IO.inspect(changeset)
        render(conn, :edit, changeset: changeset, user: existing_user)
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
