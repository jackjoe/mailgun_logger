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
          events: Ecto.Association.NotLoaded.t() | [Event.t()],
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "accounts" do
    field(:api_key, :string)
    field(:domain, :string)
    field(:is_active, :boolean, default: false)
    field(:is_eu, :boolean, default: false)

    has_many(:events, Event)

    timestamps()
  end

  def changeset(%Account{} = account, attrs \\ %{}) do
    account
    |> cast(attrs, [:api_key, :domain, :is_active, :is_eu])
    |> validate_required([:api_key, :domain])
    |> unique_constraint(:api_key)
  end
end
