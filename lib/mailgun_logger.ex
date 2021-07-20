defmodule MailgunLogger do
  require Logger

  alias MailgunLogger.Account
  alias MailgunLogger.Accounts
  alias Mailgun.Events

  @ttl 180_000

  @moduledoc """
  MailgunLogger retrieves events on a regular basis from Mailgun, who only provide a limited time of event storage.
   For efficiency and less complexity, we just retrieve events for the last two days (free accounts offer up to three days of persistance) and then insert everything. Only new events will pass the unique constraint on the db.

  We do this because, as stated in the Mailgun docs, it is not guaranteed that for a given time period, all actual events will be ready, since some take time to get into the system allthough they already happened.

  The docs suggest a half our overlap, but what gives. We go all in.
  """

  @doc """
  Main entry method, which starts a run. In a couple of steps, it will:
  - retrieve all accounts
  - for each account, get and store the events.
  """
  def run() do
    events =
      Accounts.list_active_accounts()
      |> Enum.map(&Task.async(fn -> process_account(&1) end))
      |> Enum.map(&Task.await(&1, @ttl))
      |> List.flatten()

    Slacker.new()
    |> Slacker.message("MailgunLogger logged events for #{length(events)} accounts")
    |> Slacker.send_async()
  end

  @doc """
  Process a single Mailgun account.

  - generate a valid timerange, [today - 2 days, today]
  - fetch the events for that timerange
  - persist
  """
  @spec process_account(Account.t()) :: {:ok, [Event.t()]} | {:error, Ecto.Changeset.t()}
  def process_account(%Account{} = account) do
    client = Mailgun.Client.new(account)

    client
    |> Mailgun.Events.get_events(gen_range())
    |> MailgunLogger.Events.save_events(account)
    |> get_stored_messages(client)
  end

  @doc """
  Generate a timerange from yesterday until today.
  """
  def gen_range() do
    now = DateTime.utc_now()
    yesterday = DateTime.add(now, -1 * seconds_in_day(), :second) |> DateTime.to_unix()
    today = DateTime.to_unix(now)
    %{begin: yesterday, end: today}
  end

  defp seconds_in_day(), do: 60 * 60 * 24

  defp get_stored_messages({:ok, events}, client), do: Events.get_stored_messages(client, events)
  defp get_stored_messages(x, _), do: x
end
