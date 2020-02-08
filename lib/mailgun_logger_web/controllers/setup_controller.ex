defmodule MailgunLoggerWeb.SetupController do
  use MailgunLoggerWeb, :controller

  plug(:put_layout, :setup)

  alias MailgunLogger.User
  alias MailgunLogger.Users

  def index(conn, _) do
    case Users.any_users?() do
      true ->
        redirect(conn, to: page_path(conn, :index))

      false ->
        changeset = User.changeset(%User{})
        render(conn, :index, changeset: changeset)
    end
  end

  def create_root(conn, %{"user" => params}) do
    case Users.create_admin(params) do
      {:ok, _} -> redirect(conn, to: page_path(conn, :index))
      {:error, changeset} -> render(conn, :index, changeset: changeset)
    end
  end
end
