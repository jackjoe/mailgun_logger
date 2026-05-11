defmodule MailgunLoggerWeb.Plugs.RequirePermission do
  import Plug.Conn
  alias MailgunLogger.Roles

  def init(opts), do: opts

  @spec call(any(), any()) :: any()
  def call(conn, required_action) do
    user = conn.assigns[:current_user]

    if user && Roles.can?(user, required_action) do
      conn
    else
      conn
      |> send_resp(403, "Forbidden")
      |> halt()
    end
  end
end
