defmodule JackJoe.ReleaseTasks do
  @start_apps [
    :crypto,
    :ssl,
    :myxql,
    :ecto,
    :ecto_sql
  ]

  @app :mailgun_logger

  def migrate_and_seed do
    IO.puts("|> MIGRATE_AND_SEED")

    start_services()
    _migrate()
    _seed()
    stop_services()
  end

  def migrate do
    IO.puts("|> MIGRATE")

    start_services()
    _migrate()
    stop_services()
  end

  def seed do
    IO.puts("|> SEED")

    start_services()
    _seed()
    stop_services()
  end

  # def rollback(repo, version) do
  #   IO.puts("|> ROLLBACK")
  #
  #   start_services()
  #
  #   {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  #
  #   stop_services()
  # end

  #################

  defp _migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  defp _seed do
    Enum.each(repos(), &run_seeds_for/1)
  end

  defp start_services do
    IO.puts("|> Starting dependencies...")

    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for app
    IO.puts("|> Starting repos...")

    # Switch pool_size to 2 for ecto > 3.0
    Enum.each(repos(), & &1.start_link(pool_size: 2))
  end

  defp stop_services do
    IO.puts("|> Success!")

    :init.stop()
  end

  defp run_seeds_for(repo) do
    # Run the seed script if it exists
    seed_script = priv_path_for(repo, "seeds.exs")

    if File.exists?(seed_script) do
      IO.puts("|> Running seed script...")
      Code.eval_file(seed_script)
    end
  end

  defp repos do
    Application.load(@app)
    Application.get_env(@app, :ecto_repos)
  end

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)

    repo_underscore =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    Path.join(["#{:code.priv_dir(app)}", repo_underscore, filename])
  end
end
