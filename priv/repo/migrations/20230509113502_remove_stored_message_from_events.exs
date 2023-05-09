defmodule MailgunLogger.Repo.Migrations.RemoveStoredMessageFromEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      remove(:stored_message)
    end
  end
end
