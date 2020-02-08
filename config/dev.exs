use Mix.Config

config :mailgun_logger, MailgunLoggerWeb.Endpoint,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :mailgun_logger, MailgunLoggerWeb.Endpoint,
  url: [host: System.get_env("HOST", "0.0.0.0"), scheme: "https", port: System.get_env("PORT", "4000")],
  https: [
    port: System.get_env("PORT", "4000"),
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
  ]

config :mailgun_logger, MailgunLogger.Scheduler, jobs: []
config :mailgun_logger, MailgunLogger.Mailer, adapter: Bamboo.LocalAdapter

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
