# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project. Values that come from the
# environment belong in config/runtime.exs.
import Config

config :mailgun_logger,
  ecto_repos: [MailgunLogger.Repo],
  env: config_env(),
  store_messages: false,
  page_size: 50

# Configures the endpoint
config :mailgun_logger, MailgunLoggerWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: MailgunLoggerWeb.ErrorHTML, json: MailgunLoggerWeb.ErrorJSON],
    layout: false
  ],
  live_view: [signing_salt: "ML_LV_Salt"],
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

config :phoenix,
  format_encoders: [json: Jason],
  json_library: Jason

config :flop, repo: MailgunLogger.Repo

config :ex_aws,
  debug_requests: true,
  json_codec: Jason,
  hackney_opts: [
    recv_timeout: 60_000
  ]

config :mailgun_logger, MailgunLogger.Mailer,
  adapter: Swoosh.Adapters.Mailgun,
  from: "no-reply@jackjoe.be",
  reply_to: "no-reply@jackjoe.be",
  base_url: "https://api.eu.mailgun.net/v3"

config :swoosh, :api_client, Swoosh.ApiClient.Req

config :mailgun_logger, MailgunLogger.Repo,
  pool_size: 10,
  timeout: 30_000,
  # default 50ms
  queue_target: 100,
  # default 1000ms
  queue_interval: 2_000

# Configures Elixir's Logger
config :logger,
  level: :debug,
  default_formatter: [
    format: "$time $metadata[$level] $message\n",
    metadata: [:user_id]
  ]

import_config "#{config_env()}.exs"
