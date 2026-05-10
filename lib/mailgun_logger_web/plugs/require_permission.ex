defmodule MailgunLoggerWeb.Plugs.RequirePermission do
  import Plug.Conn
  import Phoenix.Controller

  alias MailgunLogger.Roles
  alias MailgunLoggerWeb.Router.Helpers, as: Routes

  @moduledoc """
  Enforces that the authenticated user has the required permission.
  This plug expects MailgunLoggerWeb.Plugs.Auth to have assigned :current_user.
  """
  def init(permission), do: permission

  def call(conn, permission) do
    user = conn.assigns[:current_user]

    if user && Roles.can?(user, permission) do
      conn
    else
      conn
      |> put_flash(:error, "You do not have permission to access this page.")
      |> redirect(to: Routes.event_path(conn, :index))
      |> halt()
    end
  end
end
