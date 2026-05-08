defmodule MailgunLoggerWeb.Plugs.Authorize do
  import Plug.Conn
  import Phoenix.Controller

  alias MailgunLogger.Roles
  alias MailgunLoggerWeb.Router.Helpers, as: Routes

  @moduledoc """
  Plug that checks whether the current user has the required permission.
  """

  @spec init(atom()) :: atom()
  def init(permission), do: permission

  @spec call(Plug.Conn.t(), atom()) :: Plug.Conn.t()
  def call(conn, permission) do
    user = conn.assigns.current_user

    if Roles.can?(user, permission) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to access this page.")
      |> redirect(to: Routes.event_path(conn, :index))
      |> halt()
    end
  end
end
