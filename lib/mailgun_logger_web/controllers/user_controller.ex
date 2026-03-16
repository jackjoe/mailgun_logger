defmodule MailgunLoggerWeb.UserController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Roles
  alias MailgunLogger.Users
  alias MailgunLogger.User

  defp authorize!(conn, action) do
  user = conn.assigns.current_user

  if Roles.can?(user, action) do
    conn
  else
    conn
    |> put_flash(:error, "Not authorized")
    |> redirect(to: Routes.event_path(conn, :index))
    |> halt()
  end
end

  def index(conn, _) do
    conn = authorize!(conn, :manage_users)

    if conn.halted do
      conn
    else
      users = Users.list_users()
      render(conn, :index, users: users)
    end
  end

  def new(conn, _) do
    conn = authorize!(conn, :manage_users)

    if conn.halted do
      conn
    else
      changeset = User.changeset(%User{})
      render(conn, :new, changeset: changeset)
    end
  end

  def create(conn, %{"user" => params}) do
    conn = authorize!(conn, :manage_users)

    if conn.halted do
      conn
    else
      case Users.create_user(params) do
        {:ok, _} -> redirect(conn, to: Routes.user_path(conn, :index))
        {:error, changeset} -> render(conn, :new, changeset: changeset)
      end
    end
  end

  def edit(conn, %{"id" => id}) do
    conn = authorize!(conn, :manage_users)

    if conn.halted do
      conn
    else      user = Users.get_user!(id)
      changeset = User.changeset(user)
      render(conn, :edit, changeset: changeset, user: user)
    end
  end

  def update(conn, %{"id" => id, "user" => params}) do
    conn = authorize!(conn, :manage_users)

    if conn.halted do
      conn
    else
      user = Users.get_user!(id)

      case Users.update_user(user, params) do
        {:ok, _} ->
          redirect(conn, to: Routes.user_path(conn, :index))

        {:error, changeset} ->
          render(conn, :edit, changeset: changeset, user: user)
      end
    end
  end

  def delete(conn, %{"id" => id}) do
    conn = authorize!(conn, :manage_users)

    if conn.halted do
      conn
    else
      {:ok, _} =
        id
        |> Users.get_user!()
        |> Users.delete_user()

      conn
      |> put_flash(:info, "user deleted successfully.")
      |> redirect(to: Routes.user_path(conn, :index))
    end
  end
end
