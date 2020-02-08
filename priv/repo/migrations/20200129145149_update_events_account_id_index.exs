defmodule MailgunLogger.Repo.Migrations.UpdateEventsAccountIdIndex do
  use Ecto.Migration

  def change do
    create(index(:events, [:account_id]))
  end
end
