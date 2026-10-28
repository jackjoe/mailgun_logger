defmodule MailgunLogger do
  require Logger

  alias MailgunLogger.Account
  alias MailgunLogger.Accounts
  alias MailgunLogger.Event
  alias Mailgun.Events

  import Ecto.Query, warn: false

  @ttl 180_000

  @moduledoc """
  MailgunLogger retrieves events on a regular basis from Mailgun, who only provide a limited time of event storage.
   For efficiency and less complexity, we just retrieve events for the last two days (free accounts offer up to three days of persistance) and then insert everything. Only new events will pass the unique constraint on the db.

  We do this because, as stated in the Mailgun docs, it is not guaranteed that for a given time period, all actual events will be ready, since some take time to get into the system allthough they already happened.

  The docs suggest a half our overlap, but what gives. We go all in.

  ## Config

  There is an option to store the raw messages received from the api. In the first version of the app everything was stored in the database but the seize of the table became huge in a very short time and the raw event data did not really offer added value.
  So we opted to store that data on S3 instead of in the database.

  ```
  config :mailgun_logger,
    ecto_repos: [MailgunLogger.Repo],
    env: Mix.env(),
    store_messages: true
  ````

  If you set `store_messages` to `true` then you need to setup `ex_aws`.

  ```
  config :ex_aws,
    access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
    region: System.get_env("AWS_REGION"),
    bucket: System.get_env("AWS_BUCKET"),
    raw_path: System.get_env("RAW_PATH"),
    s3: [
      scheme: System.get_env("AWS_SCHEME"),
      port: System.get_env("AWS_PORT"),
      region: System.get_env("AWS_REGION"),
      host: System.get_env("AWS_HOST")
    ],
    debug_requests: true,
    json_codec: Jason,
    http_client: ExAws.Request.Req,
    req_opts: [receive_timeout: 60_000]
  ```

  """

  @doc """
  Main entry method, which starts a run. In a couple of steps, it will:
  - retrieve all accounts
  - for each account, get and store the events.
  """
  def run() do
    Accounts.list_active_accounts()
    |> Enum.map(&Task.async(fn -> process_account(&1) end))
    |> Enum.map(&Task.await(&1, @ttl))
    |> List.flatten()
  end

  @doc "True while a run that `run_async_if_not_running/0` started is busy."
  def running?(), do: Process.whereis(:run_task) != nil

  @doc """
  Spawns a task to fetch new e-mails. If the task is already running, it will not be started again.
  """
  def run_async_if_not_running() do
    if Process.whereis(:run_task) == nil do
      {:ok, pid} = Task.start(&run/0)
      Process.register(pid, :run_task)
    end
  end

  @doc """
  Fetch the messages of the events of the last `hours` from Mailgun again
  and store them on S3. Mailgun keeps a message for a few days only.

  In production:

      bin/production rpc "MailgunLogger.store_recent_messages(24) |> IO.inspect()"
  """
  @spec store_recent_messages(pos_integer()) :: %{stored: integer, failed: integer}
  def store_recent_messages(hours) do
    since = NaiveDateTime.add(NaiveDateTime.utc_now(), -hours * 3600, :second)

    since
    |> MailgunLogger.Events.list_events_with_storage_url()
    |> Enum.group_by(& &1.account)
    |> Enum.flat_map(fn {account, events} ->
      Events.get_stored_messages(Mailgun.Client.new(account), events)
    end)
    |> Enum.split_with(& &1.has_stored_message)
    |> then(fn {stored, failed} -> %{stored: length(stored), failed: length(failed)} end)
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

    case Mailgun.Events.get_events(client, gen_range()) do
      {:error, status, body} ->
        Accounts.record_run(account, {:error, describe_error(status, body)})
        {:error, status, body}

      {:error, reason} ->
        Accounts.record_run(account, {:error, describe_error(reason)})
        {:error, reason}

      events ->
        Accounts.record_run(account, {:ok, length(events)})

        events
        |> MailgunLogger.Events.save_events(account)
        |> get_stored_messages(client)
    end
  end

  # A short message for the accounts page, for example "401: unauthorized".
  defp describe_error(status, body) do
    message =
      case Jason.decode(body) do
        {:ok, %{"message" => message}} -> message
        {:ok, %{"Error" => message}} -> message
        _ -> String.slice(body, 0, 200)
      end

    "#{status}: #{message}"
  end

  defp describe_error(%{__exception__: true} = exception), do: Exception.message(exception)
  defp describe_error(message) when is_binary(message), do: message
  defp describe_error(reason), do: inspect(reason)

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
