defmodule MailgunLoggerWeb.UserController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Users
  alias MailgunLogger.User

  def index(conn, _) do
    users = Users.list_users()
    render(conn, :index, users: users)
  end

  def new(conn, _) do
    changeset = User.changeset(%User{})
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
    changeset = User.changeset(user)
    # We fetchen de role_id van de gebruiker waar we een aanpassing kunnen maken zodat de template de huidige rol van de gebruiker kan weergeven, in plaats van de eerste waarde uit de lijst.
    user_role_id = user.roles |> List.first() |> Map.get(:id)
    render(conn, :edit, changeset: changeset, user: user, user_role_id: user_role_id)
  end

  def update(conn, %{"id" => id, "user" => params}) do
    user = Users.get_user!(id)
    current_user = conn.assigns[:current_user]

    current_user_id = current_user.id
    current_role_id = current_user.roles |> List.first() |> Map.get(:id)
    target_user_id = user.id
    target_user_role_id = params["role"] |> String.to_integer()

    # Met deze if statement weerhou ik de ingelogde gebruiker ervan zichzelf een andere rol toe te kennen
    if current_user_id == target_user_id && current_role_id != target_user_role_id do
      conn
      |> put_flash(:error, "You cannot change your own role.")
      |> redirect(to: Routes.user_path(conn, :edit, user))
    else
      case Users.update_user(user, params) do
        {:ok, _user} ->
          redirect(conn, to: Routes.user_path(conn, :index))

        {:error, changeset} ->
          render(conn, :edit, changeset: changeset, user: user)
      end
    end
  end

  # Extra veiligheid dat de ingelogde gebruiker zichzelf niet kan verwijderen
  def delete(conn, %{"id" => id}) do

    id = id |> String.to_integer()
    current_user = conn.assigns[:current_user]

    if id == current_user.id do
      conn
      |> put_flash(:error, "You can't delete yourself.")
      |> redirect(to: "/users")
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
