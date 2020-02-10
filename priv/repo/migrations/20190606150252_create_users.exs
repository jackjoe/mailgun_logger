defmodule MailgunLogger.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:email, :string, size: 75)
      add(:firstname, :string, size: 75, default: "")
      add(:lastname, :string, size: 75, default: "")
      add(:encrypted_password, :string)
      add(:token, :string, size: 75)
      add(:reset_token, :string, default: nil)

      timestamps()
    end

    create(unique_index(:users, [:email]))
    create(unique_index(:users, [:token]))
  end
end
