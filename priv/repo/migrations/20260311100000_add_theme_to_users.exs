defmodule MailgunLogger.Repo.Migrations.AddThemeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:theme, :string, default: "system")
    end
  end
end
