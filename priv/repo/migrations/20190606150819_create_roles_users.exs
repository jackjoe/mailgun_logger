defmodule MailgunLogger.Repo.Migrations.CreateRolesUsers do
  use Ecto.Migration

  def change do
    create table(:roles_users) do
      add(:role_id, references(:roles))
      add(:user_id, references(:users))

      timestamps()
    end
  end
end
