defmodule MailgunLogger.Application do
  @moduledoc false

  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    check_store_raw()

    Envy.auto_load
    Envy.reload_config
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

  defp check_store_raw() do
    if Application.get_env(:mailgun_logger, :store_messages) and
         is_nil(Application.get_env(:ex_aws, :access_key_id)) do
      raise "If `store_messages` is on, you need to configure ex_aws"
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MailgunLoggerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
