defmodule MailgunLogger.Repo.Migrations.RemoveRawColumnFromEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      remove(:stored_message)
      add(:has_stored_message, :boolean, default: false)
    end
  end
end
