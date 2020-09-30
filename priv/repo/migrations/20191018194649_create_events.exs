defmodule MailgunLogger.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add(:api_id, :string, size: 50)
      add(:event, :string)
      add(:log_level, :string, size: 50)
      add(:method, :string, size: 50)
      add(:recipient, :string)
      add(:timestamp, :utc_datetime)
      add(:message_from, :string)
      add(:message_subject, :string)
      add(:message_id, :string, size: 100)
      add(:message_to, :string)
      add(:delivery_attempt, :integer)
      add(:raw, :json)
      add(:account_id, references("accounts"))
      timestamps()
    end

    create(unique_index(:events, [:api_id]))
  end
end
