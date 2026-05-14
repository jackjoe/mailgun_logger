defmodule MailgunLoggerWeb.UserController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Users
  alias MailgunLogger.User

  def index(conn, _) do
    users = Users.list_users()
    render(conn, :index, users: users)
  end

  # def new(conn, _) do
  #   changeset = User.changeset(%User{})
  #   render(conn, :new, changeset: changeset)
  # end

  def new(conn, _) do
    changeset = User.changeset(%User{})
    render(conn, :new, changeset: changeset, new?: true, current_user: conn.assigns[:current_user])
  end

  # def create(conn, %{"user" => params}) do
  #   case Users.create_user(params) do
  #     {:ok, _} -> redirect(conn, to: Routes.user_path(conn, :index))
  #     {:error, changeset} -> render(conn, :new, changeset: changeset)
  #   end
  # end

  def create(conn, %{"user" => params}) do
    role = Map.get(params, "role", "member")
    case Users.create_user_with_role(params, role) do
      {:ok, _} -> redirect(conn, to: Routes.user_path(conn, :index))
      {:error, changeset} -> render(conn, :new, changeset: changeset, new?: true, current_user: conn.assigns[:current_user])
    end
  end

  # def edit(conn, %{"id" => id}) do
  #   user = Users.get_user!(id)
  #   changeset = User.changeset(user)
  #   render(conn, :edit, changeset: changeset, user: user)
  # end

  def edit(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    changeset = User.update_changeset(user)
    render(conn, :edit, changeset: changeset, user: user, new?: false, current_user: conn.assigns[:current_user])
  end

  # def update(conn, %{"id" => id, "user" => params}) do
  #   user = Users.get_user!(id)

  #   case Users.update_user(user, params) do
  #     {:ok, _} ->
  #       redirect(conn, to: Routes.user_path(conn, :index))

  #     {:error, changeset} ->
  #       render(conn, :edit, changeset: changeset, user: user)
  #   end
  # end

  def update(conn, %{"id" => id, "user" => params}) do
    user = Users.get_user!(id)
    role = Map.get(params, "role")

    # to check current user's role
    current_user = conn.assigns[:current_user]

    # Block self-downgrade and upgrade
    if to_string(user.id) == to_string(current_user.id) && role != hd(current_user.roles).name do
      conn
      |> put_flash(:error, "You can't change your own role.")
      |> redirect(to: Routes.user_path(conn, :edit, user))
    else
      with {:ok, user} <- Users.update_user(user, params),
          {:ok, _} <- (if role, do: Users.update_user_role(user, role), else: {:ok, user}) do
        redirect(conn, to: Routes.user_path(conn, :index))
      else
        {:error, changeset} -> render(conn, :edit, changeset: changeset, user: user, current_user: conn.assigns[:current_user])
      end
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
