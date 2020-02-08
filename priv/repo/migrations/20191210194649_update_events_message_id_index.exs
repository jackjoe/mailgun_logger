defmodule MailgunLogger.Repo.Migrations.UpdateEventsMessageIdIndex do
  use Ecto.Migration

  def change do
    create(index(:events, [:message_id]))
  end
end
