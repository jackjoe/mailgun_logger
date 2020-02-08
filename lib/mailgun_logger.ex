defmodule MailgunLogger do
  require Logger

  alias MailgunLogger.Account
  alias MailgunLogger.Accounts

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
  def process_account(%Account{} = account) do
    range = gen_range()
    params = %{} |> Map.merge(range)

    Mailgun.Client.new(account)
    |> Mailgun.Events.get_events(params)
    |> MailgunLogger.Events.save_events(account)
  end

  @doc """
  Generate a timerange from yesterday until today.
  """
  def gen_range() do
    now = Timex.now()
    yesterday = Timex.shift(now, days: -1) |> Timex.to_unix()
    today = now |> Timex.to_unix()
    %{begin: yesterday, end: today}
  end
end
