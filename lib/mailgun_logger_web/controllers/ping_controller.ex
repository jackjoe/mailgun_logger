defmodule MailgunLoggerWeb.PingController do
  use MailgunLoggerWeb, :controller

  def ping(conn, _) do
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

    [status, text] =
      case states do
        %{db: :error} -> [503, "no_db_connection"]
        _ -> [:ok, "pong"]
      end

    conn
    |> put_status(status)
    |> text(text)
  end
end
