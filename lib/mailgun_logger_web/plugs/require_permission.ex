defmodule MailgunLoggerWeb.Plugs.RequirePermission do
  import Plug.Conn
  import Phoenix.Controller
  alias MailgunLogger.Roles
  alias MailgunLoggerWeb.Router.Helpers, as: Routes


  @moduledoc """
  plug die checkt of huidige gebruiker de vereiste permission heeft
  if false wordt gebruiker geredirect naar events page
  reminder: plug (elixir) = middleware
  """

  def init(action), do: action
  def call(conn, action) do
    user = conn.assigns[:current_user]

    if user && Roles.can?(user, action) do
      # user heeft toestemming, ga verder
      conn
    else
      # geen permi -> redirect naar events
      conn
      |> put_flash(:error, "je hebt geen permissie tot deze pagina")
      |> redirect(to: Routes.event_path(conn, :index))
      |> halt()
    end

  end
end
