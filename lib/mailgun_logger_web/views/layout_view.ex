defmodule MailgunLoggerWeb.LayoutView do
  use MailgunLoggerWeb, :view
  @moduledoc false

  # Door mijn get_role functie te definieren kan ik deze ook gebruiken in de LiveView templates
  alias MailgunLogger.UserRole
  def get_current_user_role(user) do
    UserRole.get_current_user_role(user)
  end
end
