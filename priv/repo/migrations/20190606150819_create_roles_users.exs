defmodule MailgunLogger.Repo.Migrations.CreateRolesUsers do
  use Ecto.Migration

  def change do
    create table(:roles_users) do
      add(:role_id, references(:roles, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end
  end
end
