defmodule MailgunLoggerWeb.AuthController do
  use MailgunLoggerWeb, :controller
  import MailgunLoggerWeb.Gettext

  alias MailgunLogger.Users
  alias MailgunLoggerWeb.Plugs.Auth

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    auth = Users.authenticate(email, password)
    case auth do
      {:ok, user} ->
        conn
        |> Auth.sign_in(user)
        |> redirect(to: page_path(conn, :index))

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
    |> redirect(to: page_path(conn, :index))
  end
end
