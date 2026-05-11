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
    user = %User{}
    changeset = User.changeset(user, %{})
    current_user = conn.assigns.current_user
    selected_role_ids = []
    render(conn, :new, user: user, current_user: current_user, changeset: changeset, roles: role_options(), selected_role_ids: selected_role_ids)
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
    selected_role_ids = Enum.map(user.roles, & &1.id)
    render(conn, :edit, changeset: changeset, user: user, current_user: current_user, roles: role_options(), selected_role_ids: selected_role_ids)
  end

  def update(conn, %{"id" => id, "user" => params}) do
    user = Users.get_user!(id)
    current_user = conn.assigns.current_user

    param_role_ids =
      params
      |> Map.get("role_ids", [])
      |> Enum.map(&String.to_integer/1)

    conn =
      if current_user.id == user.id do
        current_role_ids = Enum.map(current_user.roles, & &1.id)
        current_highest_role = Enum.min(current_role_ids)
        param_highest_role = Enum.min(param_role_ids)

        cond do
          param_highest_role < current_highest_role ->
            conn
            |> put_flash(:error, "You cannot promote yourself to a higher role.")
            |> redirect(to: Routes.user_path(conn, :edit, user.id))
            |> halt()

          current_highest_role not in param_role_ids ->
            conn
            |> put_flash(:error, "You cannot remove your highest role.")
            |> redirect(to: Routes.user_path(conn, :edit, user.id))
            |> halt()

          true ->
            conn
        end
      else
        conn
      end

    if conn.halted do
      conn
    else
      roles = Roles.get_roles_by_id(param_role_ids)

      case Users.update_user(user, params, roles) do
        {:ok, _} ->
          redirect(conn, to: Routes.user_path(conn, :index))

        {:error, changeset} ->
          render(conn, :edit, changeset: changeset, user: user, current_user: current_user, roles: role_options())
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
