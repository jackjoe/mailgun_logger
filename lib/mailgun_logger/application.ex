defmodule MailgunLogger.Application do
  @moduledoc false

  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: MailgunLogger.PubSub},
      {MailgunLogger.Repo, []},
      {MailgunLoggerWeb.Endpoint, []}
    ]

    children =
      if Application.get_env(:mailgun_logger, :env) not in [:test, :dev] do
        children ++ [{MailgunLogger.Scheduler, []}]
      else
        children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MailgunLogger.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MailgunLoggerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
