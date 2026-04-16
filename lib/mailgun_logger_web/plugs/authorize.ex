defmodule MailgunLoggerWeb.Plugs.Authorize do
  import Plug.Conn
  import Phoenix.Controller
  alias MailgunLoggerWeb.Router.Helpers
  alias MailgunLogger.Roles

  def init(action), do: action

  def call(conn, action) do
    user = conn.assigns.current_user

    if Roles.can?(user, action) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> redirect(to: Helpers.event_path(conn, :index))
      |> halt()
    end
  end
end
