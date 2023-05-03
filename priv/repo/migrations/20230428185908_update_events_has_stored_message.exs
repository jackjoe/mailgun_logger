defmodule MailgunLogger.Repo.Migrations.UpdateEventsWithHasStoredMessage do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add(:has_stored_message, :boolean, default: false)
    end
  end
end
