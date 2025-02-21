defmodule MailgunLogger.Repo.Migrations.AddEventsIndex do
  use Ecto.Migration

  def change do
    execute """
      CREATE INDEX events_delivered_timestamp_inserted_at_id_idx ON events (event, timestamp DESC, inserted_at DESC, id);
    """
  end
end
