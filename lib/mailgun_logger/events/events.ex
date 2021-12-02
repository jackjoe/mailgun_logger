defmodule MailgunLogger.Events do
  @moduledoc false

  import Ecto.Query, warn: false

  alias MailgunLogger.Account
  alias MailgunLogger.Event
  alias MailgunLogger.Repo
  alias MailgunLoggerWeb.PagingHelpers

  @spec list_events_paged(map()) :: any
  def list_events_paged(params) do
    params = PagingHelpers.scrivener_format_params(params)

    # IO.inspect(params, label: "index params")

    Event
    |> select([n], n)
    |> join(:inner, [n], a in assoc(n, :account))
    |> order_by([n], desc: n.id)
    |> preload([_, a], account: a)
    |> Pager.paginate(Event, params)
  end

  def search_events(params) do
    params =
      params
      |> parse_search_params()
      |> Map.put("page_size", 50)
      |> PagingHelpers.scrivener_format_params()

    # IO.inspect(params, label: "search params")

    Event
    |> select([n], n)
    |> join(:inner, [n], a in assoc(n, :account))
    |> build_search_query(params)
    |> order_by([n], desc: n.id)
    |> preload([_, a], account: a)
    |> Repo.paginate(params)
  end

  defp build_search_query(queryable, params) do
    queryable
    |> search(:subject, params["subject"])
    |> search(:recipient, params["recipient"])
    |> search(:from, params["from"])
    |> filter(:event, params["event"])
  end

  defp search(q, _, s) when s in ["", nil], do: q
  defp search(q, :subject, s), do: where(q, [n], like(n.message_subject, ^"%#{s}%"))
  defp search(q, :from, f), do: where(q, [n], like(n.message_from, ^"%#{f}%"))
  defp search(q, :recipient, r), do: where(q, [n], like(n.recipient, ^"%#{r}%"))

  defp filter(q, :event, []), do: q
  defp filter(q, :event, types), do: where(q, [n], n.event in ^types)

  defp parse_search_params(params) do
    subject = Map.get(params, "subject", nil)
    recipient = Map.get(params, "recipient", nil)
    from = Map.get(params, "from", nil)

    accepted = checkbox_string_prop(params, "accepted")
    delivered = checkbox_string_prop(params, "delivered")
    opened = checkbox_string_prop(params, "opened")
    event = [accepted, delivered, opened] |> Enum.reject(&is_nil(&1))

    Map.merge(params, %{
      "subject" => subject,
      "event" => event,
      "recipient" => recipient,
      "from" => from
    })
  end

  defp checkbox_string_prop(params, prop) do
    if Map.get(params, prop, nil) == "true",
      do: prop,
      else: nil
  end

  @spec get_event(number) :: Event.t()
  def get_event(id) do
    Event
    |> Repo.get(id)
    |> put_linked_events()
  end

  defp put_linked_events(nil), do: nil
  defp put_linked_events(event), do: Map.put(event, :linked_events, get_linked_events(event))

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

  def get_total_events(), do: Repo.aggregate(from(p in Event), :count, :id)

  @spec save_stored_message(Event.t(), map()) :: Event.t()
  def save_stored_message(event, stored_message) do
    event
    |> Event.changeset_stored_message(stored_message)
    |> Repo.update()
  end
end
