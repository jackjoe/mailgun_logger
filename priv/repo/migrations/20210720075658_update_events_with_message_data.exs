defmodule MailgunLogger.Repo.Migrations.UpdateEventsWithMessageData do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add(:stored_message, :map, default: %{})
    end
  end
end
