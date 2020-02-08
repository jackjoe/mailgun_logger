defmodule MailgunLogger.Scheduler do
  @moduledoc false
  use Quantum.Scheduler, otp_app: :mailgun_logger
end
