defmodule MailgunLoggerWeb.Plugs.SetupCheck do
  import Phoenix.Controller

  alias MailgunLoggerWeb.Router.Helpers, as: Routes
  alias MailgunLogger.Users

  @moduledoc """
  Plug that checks if the app has been setup. If there are no users in the database, redirect traffic towards a page where the system admin can be setup.
  """

  @spec init(any) :: any
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def call(conn, _) do
    case Users.any_users?() do
      true -> conn
      false -> redirect(conn, to: Routes.setup_path(conn, :index))
    end
  end
end
