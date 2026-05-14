defmodule MailgunLoggerWeb.Plugs.RoleCheck do
  import Plug.Conn
  import Phoenix.Controller
  alias MailgunLogger.Roles
  alias MailgunLoggerWeb.Router.Helpers, as: Routes

  def init(action), do: action

  def call(conn, action) do
    user = conn.assigns[:current_user]
    if Roles.can?(user, action) do
      conn
    else
      conn
      |> put_flash(:error, "No access")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end
  end
end
