defmodule MailgunLogger.Emails do
  import Swoosh.Email
  require Logger
  # import MailgunLoggerWeb.Gettext

  alias MailgunLogger.User
  alias MailgunLoggerWeb.Endpoint
  alias MailgunLoggerWeb.Router.Helpers, as: Routes

  def reset_password(user) do
    reset_url = Routes.password_reset_url(Endpoint.build_conn(), :reset_new, user.reset_token)

    content = """
    Reset your password
    ===================

    Hi!

    You requested a new password. This can be set by visiting the following link:
    #{reset_url}

    See you soon!

    Mailgun Logger
    """

    base_email()
    |> to({User.full_name(user), user.email})
    |> subject("Reset your password")
    |> text_body(content)
    |> log(:reset_password)
  end

  defp base_email do
    conf = Application.get_env(:mailgun_logger, MailgunLogger.Mailer)

    new()
    |> from(conf[:from])
  end

  @doc "Email has to be returned as a result!"
  def log(
        %Swoosh.Email{from: {_from_name, from}, to: to, subject: subject} = email,
        caller \\ :anonymous
      ) do
    to = Enum.map_join(to, ", ", fn {_name, address} -> address end)

    Logger.info("Email sent: from #{from}, to: #{to}, subject: #{subject}, caller: #{caller}")

    email
  end
end
