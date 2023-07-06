# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :mailgun_logger,
  ecto_repos: [MailgunLogger.Repo],
  env: Mix.env(),
  store_messages: true,
  ml_pagesize: System.get_env("ML_PAGESIZE") || "100"

# Configures the endpoint
config :mailgun_logger, MailgunLoggerWeb.Endpoint,
  url: [host: System.get_env("HOST")],
  secret_key_base: "9zFYul0/t5smQYyvAsFKC+Lk3AQbQrMw9Fp/OgOOJGQtHEn1dvH6WmdH26mGvv2d",
  render_errors: [view: MailgunLoggerWeb.ErrorView, accepts: ~w(html json)],
  live_view: [signing_salt: "9zFYul0/t5smQYyvAsFKC+Lk3AQbQrMw9Fp/OgOOJGQtHEn1dvH6WmdH26mGvv2d"],
  pubsub_server: MailgunLogger.PubSub

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :phoenix, :format_encoders, json: Jason
config :phoenix, :json_library, Jason

# config :scrivener_html,
#   routes_helper: MailgunLoggerWeb.Router.Helpers,
#   # If you use a single view style everywhere, you can configure it here. See View Styles below for more info.
#   view_style: :bootstrap

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :logger,
  backends: [:console],
  level: String.to_atom(System.get_env("ML_LOG_LEVEL", "debug")) || :debug

config :flop, repo: MailgunLogger.Repo

config :ex_aws,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("AWS_REGION"),
  bucket: System.get_env("AWS_BUCKET"),
  raw_path: System.get_env("RAW_PATH"),
  s3: [
    scheme: System.get_env("AWS_SCHEME"),
    port: System.get_env("AWS_PORT"),
    region: System.get_env("AWS_REGION"),
    host: System.get_env("AWS_HOST")
  ],
  debug_requests: true,
  json_codec: Jason,
  hackney_opts: [
    recv_timeout: 60_000
  ]

config :mailgun_logger, MailgunLogger.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: System.get_env("MAILGUN_DOMAIN"),
  from: System.get_env("MAILGUN_FROM") || "no-reply@jackjoe.be",
  reply_to: System.get_env("MAILGUN_REPLY_TO") || "no-reply@jackjoe.be",
  base_uri: "https://api.eu.mailgun.net/v3"

config :mailgun_logger, MailgunLogger.Repo,
  username: System.get_env("ML_DB_USER") || "root",
  password: System.get_env("ML_DB_PASSWORD"),
  database: System.get_env("ML_DB_NAME") || "mailgun_logger_dev",
  hostname: System.get_env("ML_DB_HOST") || "localhost",
  port: System.get_env("ML_DB_PORT") || 5432,
  pool_size: 10,
  timeout: 30_000,
  # default 50ms
  queue_target: 100,
  # default 1000ms
  queue_interval: 2_000

# Configures Elixir's Logger
config :logger,
  backends: [:console],
  level: :debug,
  console: [
    format: "$time $metadata[$level] $message\n",
    metadata: [:user_id]
  ],
  logger_papertrail_backend: [
    host: System.get_env("PAPERTRAIL_HOST"),
    system_name: "mailgun-logger",
    format: "$metadata $message"
  ]

import_config "#{Mix.env()}.exs"
