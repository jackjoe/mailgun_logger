defmodule MailgunLogger.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :mailgun_logger,
    adapter: Ecto.Adapters.MyXQL

  use Scrivener
end
