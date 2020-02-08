defmodule MailgunLogger.Mailer do
  use Bamboo.Mailer, otp_app: :mailgun_logger

  @spec deliver_it_later(Bamboo.Email.t() | nil) :: :nnop | Bamboo.Email.t()
  def deliver_it_later(nil), do: :noop

  def deliver_it_later(%Bamboo.Email{} = email) do
    deliver_later(email)
  end
end
