defmodule MailgunLogger.Repo.Migrations.UpdateAccountsIndex do
  use Ecto.Migration

  def change do
    drop(unique_index(:accounts, :api_key))
    create(unique_index(:accounts, [:api_key, :domain]))
  end
end
