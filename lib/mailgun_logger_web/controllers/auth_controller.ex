defmodule MailgunLoggerWeb.AuthController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.Users
  alias MailgunLoggerWeb.Plugs.Auth

  def new(conn, _params) do
    render(conn, :new, form: Phoenix.Component.to_form(%{}, as: "user"))
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Users.authenticate(email, password) do
      {:ok, user} ->
        conn
        |> Auth.sign_in(user)
        |> redirect(to: ~p"/events")

      {:error, _reason} ->
        conn
        |> put_flash(:error, gettext("Invalid user name or password"))
        |> render(:new, form: Phoenix.Component.to_form(%{"email" => email}, as: "user"))
    end
  end

  def logout(conn, _) do
    conn
    |> Auth.sign_out()
    |> put_flash(:info, gettext("Signed out"))
    |> redirect(to: ~p"/")
  end
end
