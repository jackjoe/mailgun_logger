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
        unless Roles.is?(user, :admin) or Roles.is?(user, :superuser) do
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
