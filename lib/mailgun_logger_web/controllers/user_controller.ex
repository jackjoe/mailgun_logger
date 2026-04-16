defmodule MailgunLoggerWeb.UserController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Users
  alias MailgunLogger.User
  alias MailgunLogger.Roles

  def index(conn, _) do
    users = Users.list_users()
    render(conn, :index, users: users)
  end

  def new(conn, _) do
    changeset = User.changeset(%User{})
    # laad alle beschikbare rollen voor het formulier
    roles = Roles.list_roles()
    render(conn, :new, changeset: changeset, roles: roles, selected_role_ids: [])
  end

  def create(conn, %{"user" => params}) do
    role_ids = Map.get(params, "role_ids", [])
    user_params = Map.delete(params, "role_ids")

    case Users.create_user_with_roles(user_params, role_ids) do
      {:ok, _} ->
        redirect(conn, to: Routes.user_path(conn, :index))

      {:error, changeset} ->
        roles = Roles.list_roles()
        render(conn, :new, changeset: changeset, roles: roles, selected_role_ids: role_ids)
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    changeset = User.changeset(user)
    # laad alle rollen en de huidige rollen van de gebruiker
    roles = Roles.list_roles()
    selected_role_ids = Enum.map(user.roles, & &1.id)
    render(conn, :edit, changeset: changeset, user: user, roles: roles, selected_role_ids: selected_role_ids)
  end

  def update(conn, %{"id" => id, "user" => params}) do
    current_user = conn.assigns.current_user
    user = Users.get_user!(id)
    role_ids = Map.get(params, "role_ids", [])
    user_params = Map.delete(params, "role_ids")

    # prevent dat user zijn eigen downgrade
    if self_downgrade?(current_user, user, role_ids) do
      changeset = User.changeset(user)
      roles = Roles.list_roles()
      selected_role_ids = Enum.map(user.roles, & &1.id)

      conn
      |> put_flash(:error, "Je kan je eigen rol niet verlagen.")
      |> render(:edit, changeset: changeset, user: user, roles: roles, selected_role_ids: selected_role_ids)
    else
      case Users.update_user_with_roles(user, user_params, role_ids) do
        {:ok, _} ->
          redirect(conn, to: Routes.user_path(conn, :index))

        {:error, changeset} ->
          roles = Roles.list_roles()
          render(conn, :edit, changeset: changeset, user: user, roles: roles, selected_role_ids: role_ids)
      end
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Users.get_user!(id)

    # Verwijder eerst de rollen voor we de user deleten
    {:ok, user} = Users.update_user_with_roles(user, %{}, [])
    {:ok, _} = Users.delete_user(user)

    conn
    |> put_flash(:info, "user deleted successfully.")
    |> redirect(to: Routes.user_path(conn, :index))
  end

  # check od user zijn eigen wilt downgrade
  defp self_downgrade?(current_user, user, new_role_ids) do
    if current_user.id == user.id do
      elevated_roles = Enum.filter(user.roles, &(&1.name in ["admin", "superuser"]))
      elevated_role_ids = Enum.map(elevated_roles, & &1.id)
      new_role_ids_int = Enum.map(new_role_ids, &String.to_integer/1)


      # true als er een verhoogde rol is die niet meer in de nieuwe rollen zit
      Enum.any?(elevated_role_ids, &(&1 not in new_role_ids_int))
    else

      false

    end

  end
end
