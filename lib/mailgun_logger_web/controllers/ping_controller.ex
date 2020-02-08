defmodule MailgunLoggerWeb.PingController do
  use MailgunLoggerWeb, :controller

  def ping(conn, _) do
    # static_path = "#{:code.priv_dir(:mailgun_logger)}/static"

    states =
      %{}
      # DB Connection check
      |> Map.put(
        :db,
        try do
          {state, _} = Ecto.Adapters.SQL.query(MailgunLogger.Repo, "SELECT 1")
          state
        rescue
          _e in DBConnection.ConnectionError -> :error
        end
      )

    # Assets compilation check
    # |> Map.put(
    #   :assets,
    #   case Path.wildcard("#{static_path}/js/app.min-*.js") do
    #     [] -> :error
    #     _ -> :ok
    #   end
    # )

    [status, text] =
      case states do
        %{db: :error} -> [503, "no_db_connection"]
        # %{assets: :error} -> [503, "assets_not_found"]
        _ -> [:ok, "pong"]
      end

    conn
    |> put_status(status)
    |> text(text)
  end
end
