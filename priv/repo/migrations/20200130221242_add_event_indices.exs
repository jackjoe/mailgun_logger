defmodule MailgunLogger.Repo.Migrations.AddEventIndices do
  use Ecto.Migration

  def change do
    create(index(:events, [:recipient]))
    create(index(:events, [:event]))
    create(index(:events, [:message_subject]))
    create(index(:events, [:message_from]))
    create(index(:events, [:message_to]))
  end
end
