defmodule MailgunLogger.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mailgun_logger,
      version: "2202.4.1",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers(),
      aliases: aliases(),
      deps: deps(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
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
        :runtime_tools
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
      {:argon2_elixir, "~> 3.0"},
      {:bamboo, "~> 2.0"},
      {:bamboo_phoenix, "~> 1.0"},
      {:decimal, "~> 2.0"},
      {:ecto_sql, "~> 3.0"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:ex_machina, "~> 2.3", only: :test},
      {:excoveralls, "~> 0.10", only: :test},
      {:gettext, "~> 0.16"},
      {:hackney, "~> 1.12"},
      {:httpoison, "~> 1.4"},
      {:jason, "~> 1.3"},
      {:scrivener_ecto, "~> 2.0", override: true},
      # WAITING FOR PR {:scrivener_html, "~> 1.8"},
      {:scrivener_html,
       git: "https://github.com/jaimeiniesta/scrivener_html.git", branch: "relax_phoenix_dep"},
      {:phoenix, "~> 1.6.6"},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug_cowboy, "~> 2.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_view, "~> 0.17.6"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:plug, "~> 1.7"},
      {:myxql, "~> 0.3"},
      {:quantum, "~> 3.4"},
      {:sweet_xml, "~> 0.6"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.reset_test": ["ecto.drop", "ecto.create", "ecto.migrate"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
