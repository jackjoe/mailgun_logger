defmodule MailgunLogger.Events do
  @moduledoc false

  import Ecto.Query, warn: false

  alias MailgunLogger.Account
  alias MailgunLogger.Event
  alias MailgunLogger.Repo
  alias MailgunLoggerWeb.PagingHelpers

  defp list_events_query() do
    Event
    |> select([n, a], %{
      id: n.id,
      event: n.event,
      log_level: n.log_level,
      message_from: n.message_from,
      message_subject: n.message_subject,
      recipient: n.recipient,
      timestamp: n.timestamp,
      has_stored_message: fragment("IF(? IS NOT NULL, TRUE, FALSE)", n.stored_message),
      account_domain: a.domain
    })
    |> join(:inner, [n], a in assoc(n, :account))
    |> order_by([n], desc: n.timestamp)
  end

  def search_events(params) do
    params =
      params
      |> parse_search_params()
      |> Map.put("page_size", 50)
      |> PagingHelpers.scrivener_format_params()

    list_events_query()
    |> build_search_query(params)
    |> Repo.paginate(params)
  end

  defp build_search_query(queryable, params) do
    queryable
    |> search(:subject, params["subject"])
    |> search(:recipient, params["recipient"])
    |> search(:from, params["from"])
    |> search(:account, params["account"])
    |> filter(:event, params["event"])
  end

  defp search(q, _, s) when s in ["", nil], do: q
  defp search(q, :subject, s), do: where(q, [n], like(n.message_subject, ^"%#{s}%"))
  defp search(q, :from, f), do: where(q, [n], like(n.message_from, ^"%#{f}%"))
  defp search(q, :recipient, r), do: where(q, [n], like(n.recipient, ^"%#{r}%"))
  defp search(q, :account, a), do: where(q, [n], n.account_id == ^a)

  defp filter(q, :event, []), do: q
  defp filter(q, :event, types), do: where(q, [n], n.event in ^types)

  defp parse_search_params(params) do
    subject = Map.get(params, "subject")
    recipient = Map.get(params, "recipient")
    from = Map.get(params, "from")
    account = Map.get(params, "account")

    accepted = checkbox_string_prop(params, "accepted")
    delivered = checkbox_string_prop(params, "delivered")
    opened = checkbox_string_prop(params, "opened")
    failed = checkbox_string_prop(params, "failed")
    event = [accepted, delivered, opened, failed] |> Enum.reject(&is_nil(&1))

    Map.merge(params, %{
      "subject" => subject,
      "event" => event,
      "recipient" => recipient,
      "from" => from,
      "account" => account
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
