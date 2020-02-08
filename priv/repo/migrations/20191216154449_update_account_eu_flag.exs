defmodule MailgunLogger.Repo.Migrations.UpdateAccountEuFlag do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add(:is_eu, :boolean, default: false)
    end
  end
end
