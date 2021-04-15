defmodule MailgunLogger.Emails do
  use Bamboo.Phoenix, view: MailgunLoggerWeb.EmailView
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

  def test_mail(recipient) do
    base_email()
    |> to(recipient)
    |> subject("test")
    |> text_body("test")
  end

  defp base_email do
    conf = Application.get_env(:mailgun_logger, MailgunLogger.Mailer)

    new_email()
    |> from(conf[:from])
  end

  @doc "Email has to be returned as a result!"
  def log(
        %Bamboo.Email{from: from, to: to, subject: subject} = email,
        caller \\ :anonymous
      ) do
    to =
      case to do
        {_name, email} -> email
        emails when is_list(emails) -> "#{inspect(emails)}"
        email when is_binary(email) -> email
        other -> "error_parsing_email (#{inspect(other)})"
      end

    from =
      case from do
        {_name, email} -> email
        email -> email
      end

    Logger.info("Email sent: from #{from}, to: #{to}, subject: #{subject}, caller: #{caller}")

    email
  end
end
