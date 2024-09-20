# Een Plug voor page authorization => Niet elke pagina is beschikbaar voor een member
defmodule MailgunLoggerWeb.Plugs.Authorize do
  import Phoenix.Controller

  alias MailgunLogger.UserRole

  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = Map.get(conn.assigns, :current_user)
    user_role = UserRole.get_current_user_role(current_user)

    if current_user && user_role !== "member" do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to visit this page.")
      |> redirect(to: "/")
    end
  end
end
