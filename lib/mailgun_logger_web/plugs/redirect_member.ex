defmodule MailgunLoggerWeb.Plugs.RedirectMember do
  import Plug.Conn
  import Phoenix.Controller

  alias MailgunLogger.Roles
  alias MailgunLogger.User
  alias MailgunLoggerWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      %User{} = user ->
        if Roles.is?(user, :member) do
          conn
          |> redirect(to: Routes.event_path(conn, :index))
          |> halt()
        else
          conn
        end
      _ ->
        conn
    end
  end


end
