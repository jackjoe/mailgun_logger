defmodule MailgunLoggerWeb.AccountHTML do
  @moduledoc false
  use MailgunLoggerWeb, :html

  embed_templates("account_html/*")

  @doc """
  Renders an account form.
  """
  attr(:changeset, Ecto.Changeset, required: true)
  attr(:action, :string, required: true)

  def account_form(assigns)
end
