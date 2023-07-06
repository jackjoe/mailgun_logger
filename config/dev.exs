import Config

port = System.get_env("PORT") || "7000"

config :mailgun_logger, MailgunLoggerWeb.Endpoint,
  url: [
    host: System.get_env("HOST", "0.0.0.0"),
    scheme: "https",
    port: port
  ],
  https: [
    port: port,
    cipher_suite: :strong,
    keyfile: "priv/cert/selfsigned_key.pem",
    certfile: "priv/cert/selfsigned.pem"
  ],
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/mailgun_logger_web/views/.*(ex)$},
      ~r{lib/mailgun_logger_web/templates/.*(eex)$}
    ]
  ],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]

config :ex_aws,
  raw_path: "_dev_mailgun_logger/messages"

config :mailgun_logger, MailgunLogger.Scheduler, jobs: []
# config :mailgun_logger, MailgunLogger.Mailer, adapter: Bamboo.LocalAdapter

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
