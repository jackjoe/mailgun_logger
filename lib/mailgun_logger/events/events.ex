defmodule MailgunLogger.Events do
  @moduledoc false

  import Ecto.Query, warn: false

  alias MailgunLogger.Account
  alias MailgunLogger.Event
  alias MailgunLogger.Repo

  def search_events(params, opts \\ []) do
    params = init_filters(params)

    fields =
      Keyword.get(
        opts,
        :fields,
        ~w(id api_id event log_level method recipient timestamp message_from message_subject)a
      )

    Event
    |> select([e], ^fields)
    |> select_merge([e], %{
      failure_reason:
        fragment(
          "CASE WHEN ? = 'failed' THEN ? -> 'delivery-status' ->> 'message' END",
          e.event,
          e.raw
        )
    })
    |> Flop.validate_and_run(params,
      for: Event,
      replace_invalid_params: true,
      default_limit: Application.get_env(:mailgun_logger, :page_size)
    )
  end

  @csv_header ~w(timestamp_utc event log_level method account from recipient subject message_id failure_reason)

  @doc """
  Streams the events that match the filters in `params` as CSV lines, newest
  first and at most `limit` events. Calls `fun` with the stream inside a
  transaction, which a database stream needs, and returns `{:ok, result}`.
  """
  def export_csv(params, limit, fun) do
    {:ok, flop} =
      Flop.validate(init_filters(params), for: Event, replace_invalid_params: true)

    query =
      from(e in Event,
        join: a in assoc(e, :account),
        limit: ^limit,
        select: [
          e.timestamp,
          e.event,
          e.log_level,
          e.method,
          a.domain,
          e.message_from,
          e.recipient,
          e.message_subject,
          e.message_id,
          fragment(
            "CASE WHEN ? = 'failed' THEN ? -> 'delivery-status' ->> 'message' END",
            e.event,
            e.raw
          )
        ]
      )
      |> Flop.filter(flop, for: Event)
      |> Flop.order_by(flop, for: Event)

    Repo.transaction(
      fn ->
        query
        |> Repo.stream(max_rows: 1000)
        |> Stream.map(&csv_line/1)
        |> then(&Stream.concat([csv_line(@csv_header)], &1))
        |> fun.()
      end,
      timeout: :infinity
    )
  end

  defp csv_line(values), do: [Enum.map_intersperse(values, ",", &csv_value/1), "\r\n"]

  defp csv_value(nil), do: ""
  defp csv_value(%NaiveDateTime{} = at), do: Calendar.strftime(at, "%Y-%m-%d %H:%M:%S")

  defp csv_value(value) do
    value = to_string(value)

    # A spreadsheet runs a cell that starts with one of these characters as a
    # formula. Senders choose the subject, so neutralize it.
    value = if String.starts_with?(value, ["=", "+", "-", "@"]), do: "'" <> value, else: value

    if String.contains?(value, [",", "\"", "\n", "\r"]),
      do: [?", String.replace(value, "\"", "\"\""), ?"],
      else: value
  end

  def init_filters(%{"filters" => filters} = params) do
    filters =
      filters
      |> Enum.map(fn {_k, v} ->
        v
        |> Enum.map(fn
          {"value", v} when is_binary(v) -> {"value", String.trim(v)}
          {k, v} -> {k, v}
        end)
        |> Enum.into(%{})
      end)
      |> Enum.reject(fn v -> v["value"] == "" end)
      |> Enum.with_index()
      |> Enum.into(%{}, fn {v, i} -> {to_string(i), v} end)

    %{params | "filters" => filters}
  end

  def init_filters(params) do
    Map.put(params, "filters", %{})
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
    |> Map.put("delivery_attempt", get_in(event, ["delivery-status", "attempt-no"]))
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

  @spec has_stored_message(Event.t()) :: Event.t()
  def has_stored_message(event) do
    event
    |> Event.changeset_has_stored_message()
    |> Repo.update()
  end

  @stats_ranges %{
    "24h" => {86_400, "hour"},
    "7d" => {7 * 86_400, "day"},
    "30d" => {30 * 86_400, "day"}
  }

  @doc """
  The period for a stats range ("24h", "7d" or "30d") that ends at `now`, the
  start of the period before it, and the size of a chart bucket.
  """
  def stats_period(range, now) do
    {seconds, bucket} = Map.get(@stats_ranges, range, @stats_ranges["24h"])
    from = NaiveDateTime.add(now, -seconds)

    %{from: from, to: now, previous_from: NaiveDateTime.add(from, -seconds), bucket: bucket}
  end

  @doc "Counts the events per type from `from` (inclusive) until `to` (exclusive)."
  def count_events_by_type(from, to, account_id) do
    from
    |> period_query(to, account_id)
    |> group_by([e], e.event)
    |> select([e], {e.event, count(e.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Counts the events per type for each hour or day bucket in the period. Buckets
  without events have empty counts.
  """
  def event_volume(from, to, bucket, account_id) when bucket in ["hour", "day"] do
    events =
      from
      |> period_query(to, account_id)
      |> select([e], %{at: fragment("date_trunc(?, ?)", ^bucket, e.timestamp), event: e.event})

    counts =
      from(e in subquery(events), group_by: [e.at, e.event], select: {e.at, e.event, count()})
      |> Repo.all()
      |> Enum.group_by(
        fn {at, _event, _count} -> NaiveDateTime.truncate(at, :second) end,
        fn {_at, event, count} -> {event, count} end
      )

    from
    |> truncate(bucket)
    |> Stream.iterate(&NaiveDateTime.add(&1, bucket_seconds(bucket)))
    |> Enum.take_while(&(NaiveDateTime.compare(&1, to) == :lt))
    |> Enum.map(&%{at: &1, counts: Map.new(Map.get(counts, &1, []))})
  end

  @doc "The most common delivery status messages of failed events."
  def top_failure_reasons(from, to, account_id, limit) do
    reason =
      dynamic(
        [e],
        fragment("coalesce(? -> 'delivery-status' ->> 'message', '(no reason)')", e.raw)
      )

    top_failed_by(from, to, account_id, limit, reason)
  end

  @doc "The recipient domains with the most failed events."
  def top_failing_domains(from, to, account_id, limit) do
    domain = dynamic([e], fragment("lower(split_part(?, '@', 2))", e.recipient))
    top_failed_by(from, to, account_id, limit, domain)
  end

  defp top_failed_by(from, to, account_id, limit, key) do
    failed =
      from
      |> period_query(to, account_id)
      |> where([e], e.event == "failed")
      |> select(^%{key: key})

    from(f in subquery(failed),
      group_by: f.key,
      select: {f.key, count()},
      order_by: [desc: count(), asc: f.key],
      limit: ^limit
    )
    |> Repo.all()
  end

  defp period_query(from, to, account_id) do
    query = where(Event, [e], e.timestamp >= ^from and e.timestamp < ^to)
    if account_id, do: where(query, [e], e.account_id == ^account_id), else: query
  end

  defp truncate(at, "hour"), do: %{at | minute: 0, second: 0, microsecond: {0, 0}}
  defp truncate(at, "day"), do: %{at | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}

  defp bucket_seconds("hour"), do: 3600
  defp bucket_seconds("day"), do: 86_400
end
