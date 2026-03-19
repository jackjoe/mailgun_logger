defmodule MailgunLoggerWeb.UserController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Users
  alias MailgunLogger.User

  def index(conn, _) do
    users = Users.list_users()
    render(conn, :index, users: users)
  end

  def new(conn, _) do
    user = %User{current_roles: create_current_roles_map([])}
    changeset = User.changeset(user)
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => params}) do
    case Users.create_user(params) do
      {:ok, _} -> redirect(conn, to: Routes.user_path(conn, :index))
      {:error, changeset} -> render(conn, :new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Users.get_user!(id)

    # Add the current roles to the user
    user = %{user | current_roles: create_current_roles_map(user.roles)}

    changeset = User.update_changeset(user)

    render(conn, :edit, changeset: changeset, user: user)
  end

  def update(conn, %{"id" => id, "user" => params}) do
    user = Users.get_user!(id)

    current_user = conn.assigns.current_user
    effective_params =
      if current_user.id == user.id do
        # Prevent self role changes, even for forged requests
        Map.delete(params, "current_roles")
      else
        params
      end

    case Users.update_user(user, effective_params) do
      {:ok, _} ->
        redirect(conn, to: Routes.user_path(conn, :index))

      {:error, changeset} ->
        render(conn, :edit, changeset: changeset, user: user)
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

  defp create_current_roles_map(roles) do
    # Iterate over the roles in the app and try to find them in the users roles, so we can set them to true or false
    Enum.map([:member, :superuser, :admin], fn role ->
        has_role =
          Enum.any?(roles, fn r -> r.name == Atom.to_string(role) end)

        {role, has_role}
      end)
  end
end
