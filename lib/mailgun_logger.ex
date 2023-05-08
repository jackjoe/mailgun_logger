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
    hackney_opts: [
      recv_timeout: 60_000
    ]
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
      {:error, status, msg} ->
        {:error, status, msg}

      events ->
        events
        |> MailgunLogger.Events.save_events(account)
        |> get_stored_messages(client)
    end
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

  # TMP

  use Ecto.Schema
  import Ecto.Changeset

  def migrate_existing_stored_messages_to_s3(limit \\ 1_000) do
    from(e in Event, where: not is_nil(e.stored_message), limit: ^limit)
    |> MailgunLogger.Repo.all()
    |> Enum.reduce(1, fn e, acc ->
      bucket()
      |> ExAws.S3.put_object(file_path(e.api_id), Jason.encode!(e.stored_message))
      |> ExAws.request!()

      change(e, %{stored_message: nil, has_stored_message: true}) |> MailgunLogger.Repo.update()

      Process.sleep(100)
      Logger.info("Processing item #{acc}/#{limit}")
      acc + 1
    end)

    {:ok, :done}
  end

  def file_path(%{api_id: api_id}), do: file_path(api_id)
  def file_path(api_id), do: Path.join(base_dir(), file_name(api_id))
  def file_name(api_id), do: "#{api_id}.json"
  def base_dir(), do: Application.get_env(:ex_aws, :raw_path)
  def bucket(), do: Application.get_env(:ex_aws, :bucket)
end
