defmodule MailgunLogger.Repo.Migrations.ReplaceEventsPaginationIndex do
  use Ecto.Migration

  def change do
    execute(
      "CREATE INDEX IF NOT EXISTS events_timestamp_id_idx ON events (timestamp DESC, id)",
      "DROP INDEX IF EXISTS events_timestamp_id_idx"
    )

    execute(
      "DROP INDEX IF EXISTS events_timestamp_inserted_at_id_idx",
      "CREATE INDEX IF NOT EXISTS events_timestamp_inserted_at_id_idx ON events (timestamp DESC, inserted_at DESC, id)"
    )
  end
end
