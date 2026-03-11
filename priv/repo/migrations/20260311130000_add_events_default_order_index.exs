defmodule MailgunLogger.Repo.Migrations.AddEventsDefaultOrderIndex do
  use Ecto.Migration

  def change do
    execute """
              CREATE INDEX IF NOT EXISTS events_timestamp_inserted_at_id_idx
              ON events (timestamp DESC, inserted_at DESC, id)
            """,
            """
              DROP INDEX IF EXISTS events_timestamp_inserted_at_id_idx
            """
  end
end
