defmodule MailgunLoggerWeb.ProfileController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Users
  alias MailgunLogger.User
  alias MailgunLogger.Roles

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

  def edit(conn, _) do
    conn = authorize!(conn, :edit_profile)

    if conn.halted do
      conn
    else
      user = conn.assigns.current_user
      changeset = User.changeset(user)

      conn
      |> put_view(MailgunLoggerWeb.UserView)
      |> render(:profile, changeset: changeset, user: user)
    end
  end

  def update(conn, %{"user" => params}) do
    conn = authorize!(conn, :edit_profile)

    if conn.halted do
      conn
    else
      user = conn.assigns.current_user

      case Users.update_user(user, params) do
        {:ok, _} ->
          conn
          |> put_flash(:info, "Profile updated.")
          |> redirect(to: Routes.profile_path(conn, :edit))

        {:error, changeset} ->
          conn
          |> put_view(MailgunLoggerWeb.UserView)
          |> render(:profile, changeset: changeset, user: user)
      end
    end
  end
end
