defmodule MailgunLogger.Account do
  @moduledoc "Mailgun account credentials."

  use Ecto.Schema
  import Ecto.Changeset

  alias MailgunLogger.Account
  alias MailgunLogger.Event

  @type t :: %__MODULE__{
          api_key: String.t(),
          domain: String.t(),
          is_active: boolean,
          is_eu: boolean,
          last_run_at: DateTime.t() | nil,
          last_run_status: String.t() | nil,
          last_run_error: String.t() | nil,
          last_run_event_count: non_neg_integer() | nil,
          events: Ecto.Association.NotLoaded.t() | [Event.t()],
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "accounts" do
    field(:api_key, :string)
    field(:domain, :string)
    field(:is_active, :boolean, default: false)
    field(:is_eu, :boolean, default: false)
    field(:last_run_at, :utc_datetime)
    field(:last_run_status, :string)
    field(:last_run_error, :string)
    field(:last_run_event_count, :integer)

    has_many(:events, Event)

    timestamps()
  end

  def changeset(%Account{} = account, attrs \\ %{}) do
    account
    |> cast(attrs, [:api_key, :domain, :is_active, :is_eu])
    |> validate_required([:api_key, :domain])
    |> unique_constraint(:api_key, name: :accounts_api_key_domain_index)
  end

  @doc "The result of the last run that fetched the events of this account."
  def run_changeset(%Account{} = account, attrs) do
    cast(account, attrs, [:last_run_at, :last_run_status, :last_run_error, :last_run_event_count])
  end
end
