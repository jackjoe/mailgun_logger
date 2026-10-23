defmodule MailgunLoggerWeb.ProfileController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Users
  alias MailgunLogger.User

  def edit(conn, _) do
    user = conn.assigns.current_user
    changeset = User.changeset(user)

    conn
    |> put_view(html: MailgunLoggerWeb.UserHTML)
    |> render(:profile, changeset: changeset, user: user)
  end

  def update(conn, %{"user" => params}) do
    user = conn.assigns.current_user

    case Users.update_user(user, params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Profile updated.")
        |> redirect(to: ~p"/profile")

      {:error, changeset} ->
        conn
        |> put_view(html: MailgunLoggerWeb.UserHTML)
        |> render(:profile, changeset: changeset, user: user)
    end
  end
end
