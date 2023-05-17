defmodule MailgunLoggerWeb.AuthController do
  use MailgunLoggerWeb, :controller
  import MailgunLoggerWeb.Gettext

  alias MailgunLogger.Users
  alias MailgunLoggerWeb.Plugs.Auth

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Users.authenticate(email, password) do
      {:ok, user} ->
        conn
        |> Auth.sign_in(user)
        |> redirect(to: Routes.event_path(conn, :index))

      {:error, _reason} ->
        conn
        |> put_flash(:error, gettext("Invalid user name or password"))
        |> render(:new)
    end
  end

  def logout(conn, _) do
    conn
    |> Auth.sign_out()
    |> put_flash(:info, gettext("Signed out"))
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
