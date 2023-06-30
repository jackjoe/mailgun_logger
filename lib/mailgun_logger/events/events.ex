defmodule MailgunLogger.Events do
  @moduledoc false

  import Ecto.Query, warn: false

  alias MailgunLogger.Account
  alias MailgunLogger.Event
  alias MailgunLogger.Repo

  def search_events(params) do
    params = parse_search_params(params)

    Event
    # |> join(:inner, [n], a in assoc(n, :account), as: :account)
    # |> preload([n], [:account])
    |> order_by([n], desc: n.timestamp)
    |> Flop.validate_and_run(params, for: Event)
  end

  defp parse_search_params(params) do
    accepted = checkbox_string_prop(params, "accepted")
    delivered = checkbox_string_prop(params, "delivered")
    opened = checkbox_string_prop(params, "opened")
    failed = checkbox_string_prop(params, "failed")
    stored = checkbox_string_prop(params, "stored")
    event = [accepted, delivered, opened, failed, stored] |> Enum.reject(&is_nil(&1))

    Map.merge(params, %{"event" => event})
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
    |> Enum.map(fn raw ->
      event_params = prepare_raw(raw, account_id)
      Event.changeset(%Event{}, event_params)
    end)
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

  def get_event_counts_by_type() do
    from(p in Event,
      group_by: p.event,
      select: {p.event, count(p.id)}
    )
    |> Repo.all()
    |> Enum.into(%{})
  end

  @spec has_stored_message(Event.t()) :: Event.t()
  def has_stored_message(event) do
    event
    |> Event.changeset_has_stored_message()
    |> Repo.update()
  end

  def get_stats(n_hours) do
    stats =
      from(e in Event,
        group_by: [
          e.event,
          fragment("CONCAT(to_char(?, 'yyyy-mm-dd hh24:mi:ss'), ?)", e.timestamp, ":00")
        ],
        select: %{
          count: count(e.id),
          event: e.event,
          date: fragment("CONCAT(to_char(?, 'yyyy-mm-dd hh24:mi:ss'), ?)", e.timestamp, ":00")
        }
      )
      |> Repo.all()

    now =
      DateTime.utc_now()
      |> Map.put(:minute, 0)
      |> Map.put(:second, 0)
      |> DateTime.truncate(:second)

    last_n_hours = Enum.map(0..n_hours, &DateTime.add(now, &1 * -1 * 3600)) |> Enum.reverse()

    {failed, accepted, delivered, clicked, opened, stored} =
      Enum.reduce(last_n_hours, {[], [], [], [], [], []}, fn date,
                                                             {failed, accepted, delivered,
                                                              clicked, opened, stored} ->
        failed = failed ++ [get_items(stats, "failed", date)]
        accepted = accepted ++ [get_items(stats, "accepted", date)]
        delivered = delivered ++ [get_items(stats, "delivered", date)]
        clicked = clicked ++ [get_items(stats, "clicked", date)]
        opened = opened ++ [get_items(stats, "opened", date)]
        stored = stored ++ [get_items(stats, "stored", date)]

        {failed, accepted, delivered, clicked, opened, stored}
      end)

    %{
      failed: failed,
      accepted: accepted,
      delivered: delivered,
      clicked: clicked,
      opened: opened,
      stored: stored,
      last_n_hours: last_n_hours
    }
  end

  defp get_items(stats, event, date) do
    date = Calendar.strftime(date, "%Y-%m-%d %H:%M")

    case Enum.find(stats, &(&1.event == event && &1.date == date)) do
      nil -> 0
      %{count: count} -> count
    end
  end

  def bucket(), do: Application.get_env(:ex_aws, :bucket)
end
