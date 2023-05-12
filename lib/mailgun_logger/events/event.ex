defmodule MailgunLogger.Event do
  @moduledoc """
  Event data to store in the database.

  Mailgun api output:
  ```
  %{
    "campaigns" => [],
    "envelope" => %{
      "sender" => "johndoe@acme.com",
      "targets" => "foo@bar.com",
      "transport" => "smtp"
    },
    "event" => "accepted",
    "flags" => %{
      "is-authenticated" => true,
      "is-routed" => false,
      "is-system-test" => false,
      "is-test-mode" => false
    },
    "id" => "zAt3zfKeSfq3Sl999wp8JA",
    "log-level" => "info",
    "message" => %{
      "attachments" => [],
      "headers" => %{
        "from" => "John <johndoe@acme.com>",
        "message-id" => "c12831104d71337e6829bdebd0b68eba@appdomain.com",
        "subject" => "You got mail!",
        "to" => "Will.I.Am <will@iam.com>"
      },
      "size" => 6905
    },
    "method" => "http",
    "recipient" => "will@iam.com",
    "recipient-domain" => "iam.com",
    "storage" => %{
      "key" => "AgEFZcDIQLKCWVMy10S1HibnaMxcdzEZA==",
      "url" => "https://sw.api.mailgun.net/v3/domains/mail.com/messages/AgEFZcDIQLKCWVMy10S1HibnaMxcdzEZA=="
    },
    "tags" => [],
    "timestamp" => 1535296460.552516,
    "user-variables" => %{}
  }
  ```
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias MailgunLogger.Event
  alias MailgunLogger.Account

  @derive {
    Flop.Schema,
    filterable: [:event, :recipient, :message_from, :message_to, :message_subject],
    sortable: [:inserted_at],
    pagination_types: [:first, :last]
  }

  @type t :: %__MODULE__{
          api_id: String.t(),
          event: String.t(),
          log_level: String.t(),
          method: String.t(),
          recipient: String.t(),
          timestamp: NaiveDateTime.t(),
          message_from: String.t(),
          message_subject: String.t(),
          message_id: String.t(),
          message_to: String.t(),
          delivery_attempt: integer,
          raw: map(),
          linked_events: [Event.t()],
          account: Ecto.Association.NotLoaded.t() | Account.t(),
          has_stored_message: boolean(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "events" do
    field(:api_id, :string)
    field(:event, :string)
    field(:log_level, :string)
    field(:method, :string)
    field(:recipient, :string)
    field(:timestamp, :naive_datetime)
    field(:message_from, :string)
    field(:message_subject, :string)
    field(:message_id, :string)
    field(:message_to, :string)
    field(:delivery_attempt, :integer)
    field(:has_stored_message, :boolean, default: false)
    field(:raw, :map, default: %{})

    field(:linked_events, {:array, :map}, virtual: true)
    field(:account_domain, :string, virtual: true)

    belongs_to(:account, Account)

    timestamps()
  end

  def changeset(%__MODULE__{} = event, attrs \\ %{}) do
    event
    |> cast(
      attrs,
      ~w(account_id api_id event log_level method recipient message_from message_subject message_id message_to timestamp delivery_attempt raw)a
    )
    |> unique_constraint(:api_id)
  end

  def changeset_has_stored_message(%__MODULE__{} = event) do
    change(event, %{has_stored_message: true})
  end
end
