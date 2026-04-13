defmodule MailgunLoggerWeb.Authorize do
  import Plug.Conn
  import Phoenix.Controller

  alias MailgunLogger.Roles

  def require(action) do
    fn conn, _opts ->
      user = conn.assigns.current_user

      if Roles.can?(user, action) do
        conn
      else
        conn
        |> put_status(:forbidden)
        |> halt()
      end
    end
  end
end
