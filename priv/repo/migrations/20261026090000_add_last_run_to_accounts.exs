defmodule MailgunLogger.Repo.Migrations.AddLastRunToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add(:last_run_at, :utc_datetime)
      add(:last_run_status, :string)
      add(:last_run_error, :text)
      add(:last_run_event_count, :integer)
    end
  end
end
