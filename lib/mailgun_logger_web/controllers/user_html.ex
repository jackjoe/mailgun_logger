defmodule MailgunLoggerWeb.UserHTML do
  @moduledoc false
  use MailgunLoggerWeb, :html

  embed_templates("user_html/*")

  @doc """
  Renders a user form. Only a new user gets a password field.
  """
  attr(:changeset, Ecto.Changeset, required: true)
  attr(:action, :string, required: true)
  attr(:new?, :boolean, default: false)

  def user_form(assigns)
end
