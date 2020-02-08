defmodule MailgunLogger.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add(:name, :string)

      timestamps()
    end

    create(index(:roles, [:name]))
  end
end
