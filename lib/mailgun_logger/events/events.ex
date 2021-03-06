defmodule MailgunLogger.Events do
  @moduledoc false

  import Ecto.Query, warn: false

  alias MailgunLogger.Event
  alias MailgunLogger.Account
  alias MailgunLogger.Repo

  @spec list_events_paged(map()) :: any
  def list_events_paged(params) do
    params = MailgunLoggerWeb.PagingHelpers.format_pager_params(params)

    Event
    |> select([n], n)
    |> join(:inner, [n], a in assoc(n, :account))
    |> order_by([n], desc: n.id)
    |> preload([_, a], account: a)
    |> Pager.paginate(Event, params)
  end

  def search_events(q) do
    Event
    |> select([n], n)
    |> join(:inner, [n], a in assoc(n, :account))
    |> build_search_query(q)
    |> order_by([n], desc: n.id)
    |> preload([_, a], account: a)
    |> limit(200)
    |> Repo.all()
  end

  defp build_search_query(queryable, ""), do: queryable
  defp build_search_query(queryable, nil), do: queryable

  defp build_search_query(queryable, q) do
    q = "%#{q}%"

    search = false

    search = dynamic([n], ^search or like(n.event, ^q))
    search = dynamic([n], ^search or like(n.recipient, ^q))
    search = dynamic([n], ^search or like(n.message_id, ^q))
    search = dynamic([n], ^search or like(n.message_subject, ^q))
    search = dynamic([n], ^search or like(n.message_from, ^q))
    search = dynamic([n], ^search or like(n.message_to, ^q))

    where(queryable, ^search)
  end

  @spec get_event(number) :: Event.t()
  def get_event(id) do
    Repo.get(Event, id)
    |> case do
      nil -> nil
      event -> Map.put(event, :linked_events, get_linked_events(event))
    end
  end

  @spec get_linked_events(Event.t()) :: [Event.t()]
  def get_linked_events(event) do
    from(
      e in Event,
      # where: e.recipient == ^event.recipient,
      where: e.message_id == ^event.message_id,
      where: e.id != ^event.id,
      order_by: [desc: e.timestamp]
    )
    |> Repo.all()
  end

  def preload(event, assoc), do: Repo.preload(event, [assoc])

  @spec save_events(map(), Account.t()) :: {:ok, [Event.t()]} | {:error, Ecto.Changeset.t()}
  def save_events(raw_events, %Account{id: account_id}) do
    raw_events
    |> Enum.map(&prepare_raw(&1, account_id))
    |> Enum.map(&Event.changeset(%Event{}, &1))
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {changeset, index}, multi ->
      Ecto.Multi.insert(multi, Integer.to_string(index), changeset, on_conflict: :nothing)
    end)
    |> Repo.transaction(timeout: :infinity)
    |> case do
      {:ok, multi_result} ->
        {:ok, Map.values(multi_result) |> Enum.filter(&(!is_nil(&1.id)))}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @spec prepare_raw(map(), number) :: map()
  def prepare_raw(%{"message" => message} = event, account_id) do
    %{}
    |> Map.put("account_id", account_id)
    |> Map.put("timestamp", conv_event_timestamp(event))
    |> Map.put("api_id", event["id"])
    |> Map.put("log_level", event["log-level"])
    |> Map.put("delivery_attempt", event["delivery-status"]["attempt-no"])
    |> Map.put("event", event["event"])
    |> Map.put("message_from", message["headers"]["from"])
    |> Map.put("message_to", message["headers"]["to"])
    |> Map.put("message_subject", message["headers"]["subject"])
    |> Map.put("message_id", message["headers"]["message-id"])
    |> Map.put("recipient", event["recipient"])
    |> Map.put("method", event["method"])
    |> Map.put("raw", event)
  end

  defp conv_event_timestamp(%{"timestamp" => timestamp}) do
    timestamp
    |> Kernel.trunc()
    |> DateTime.from_unix!()
  end

  def get_total_events() do
    Repo.aggregate(from(p in Event), :count, :id)
  end
end
