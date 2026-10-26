defmodule MailgunLogger.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mailgun_logger,
      version: "2026.4.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      listeners: [Phoenix.CodeReloader],
      aliases: aliases(),
      deps: deps(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_deps: :transitive],
      releases: [
        production: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ],
      docs: [
        # The main page in the docs
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {MailgunLogger.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :ex_aws
      ]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:argon2_elixir, "~> 4.0"},
      {:bandit, "~> 1.13"},
      {:ecto_sql, "~> 3.13"},
      {:esbuild, "~> 0.10.1", runtime: Mix.env() == :dev},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_doc, "~> 0.40.4", only: :dev, runtime: false},
      {:ex_machina, "~> 2.3", only: :test},
      {:excoveralls, "~> 0.18.5", only: :test},
      {:flop, "~> 0.29.1"},
      {:flop_phoenix, "~> 0.27.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.3"},
      {:lazy_html, "~> 0.1.13", only: :test},
      {:multipart, "~> 0.6.1"},
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug, "~> 1.8"},
      {:postgrex, "~> 0.22.4"},
      {:quantum, "~> 3.4"},
      {:req, "~> 0.7.5"},
      {:swoosh, "~> 1.29"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.reset_test": ["ecto.drop", "ecto.create", "ecto.migrate"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
