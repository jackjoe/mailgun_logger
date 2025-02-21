defmodule MailgunLogger.Repo.Migrations.InsertedAtIndex do
  use Ecto.Migration

  def change do
    create(index(:events, [:inserted_at]))
  end
end
