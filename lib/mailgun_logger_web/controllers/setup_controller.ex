defmodule MailgunLoggerWeb.SetupController do
  use MailgunLoggerWeb, :controller

  alias MailgunLogger.User
  alias MailgunLogger.Users

  def index(conn, _) do
    if Users.any_users?() do
      redirect(conn, to: ~p"/")
    else
      changeset = User.changeset(%User{})
      render(conn, :index, changeset: changeset)
    end
  end

  def create_root(conn, %{"user" => params}) do
    # Only allow create_root if there are no users in the database yet,
    # otherwise it's possible for any unauthenticated request to this
    # endpoint to make an admin user.
    if Users.any_users?() do
      redirect(conn, to: ~p"/")
    else
      case Users.create_admin(params) do
        {:ok, _} -> redirect(conn, to: ~p"/")
        {:error, changeset} -> render(conn, :index, changeset: changeset)
      end
    end
  end
end
