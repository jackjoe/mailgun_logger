# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :mailgun_logger,
  ecto_repos: [MailgunLogger.Repo],
  env: Mix.env()

# Configures the endpoint
config :mailgun_logger, MailgunLoggerWeb.Endpoint,
  url: [host: System.get_env("HOST")],
  secret_key_base: "9zFYul0/t5smQYyvAsFKC+Lk3AQbQrMw9Fp/OgOOJGQtHEn1dvH6WmdH26mGvv2d",
  render_errors: [view: MailgunLoggerWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MailgunLogger.PubSub, adapter: Phoenix.PubSub.PG2],
  instrumenters: []

config :phoenix, :format_encoders, json: Jason
config :phoenix, :json_library, Jason

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :scrivener_html,
  routes_helper: MailgunLoggerWeb.Router.Helpers,
  view_style: :bootstrap_v4

config :logger,
  backends: [:console],
  level: :debug

config :mailgun_logger, MailgunLogger.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: System.get_env("MAILGUN_DOMAIN"),
  from: System.get_env("MAILGUN_FROM")

# Configure your database
config :mailgun_logger, MailgunLogger.Repo,
  username: System.get_env("DB_USER"),
  password: System.get_env("DB_PASSWORD"),
  database: System.get_env("DB_NAME"),
  hostname: System.get_env("DB_HOST"),
  pool_size: 10

import_config "#{Mix.env()}.exs"
