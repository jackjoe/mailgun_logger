defmodule MailgunLogger.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add(:api_key, :string, size: 255)
      add(:domain, :string, size: 255)
      add(:is_active, :boolean)
      timestamps()
    end

    create(unique_index(:accounts, [:api_key]))
  end
end
