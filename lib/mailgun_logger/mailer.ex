defmodule MailgunLogger.Mailer do
  use Swoosh.Mailer, otp_app: :mailgun_logger

  require Logger

  @doc """
  Delivers the email in a supervised task, so the caller does not wait for the
  mail provider. The response time then does not depend on whether an email
  is sent.
  """
  @spec deliver_it_later(Swoosh.Email.t() | nil) :: :noop | DynamicSupervisor.on_start_child()
  def deliver_it_later(nil), do: :noop

  def deliver_it_later(%Swoosh.Email{} = email) do
    Task.Supervisor.start_child(MailgunLogger.TaskSupervisor, fn ->
      case deliver(email) do
        {:ok, _} -> :ok
        {:error, reason} -> Logger.error("Email delivery failed: #{inspect(reason)}")
      end
    end)
  end
end
