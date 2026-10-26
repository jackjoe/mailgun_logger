defmodule MailgunLoggerWeb.EventHTML do
  @moduledoc false
  use MailgunLoggerWeb, :html

  embed_templates("event_html/*")

  def event_name(name) when name in ~w(delivered failed accepted opened) do
    assigns = %{name: name}

    ~H"""
    <span class={"log-event log-event--#{@name}"}>{@name}</span>
    """
  end

  def event_name(event_name), do: event_name

  @doc "The event and its linked events, oldest first."
  def timeline(event),
    do: Enum.sort_by([event | event.linked_events], & &1.timestamp, NaiveDateTime)

  @doc "A timestamp as 2026-10-01 02:10:00, with the relative time as tooltip."
  def event_time(timestamp) do
    assigns = %{
      iso: NaiveDateTime.to_iso8601(timestamp) <> "Z",
      ago: time_ago(timestamp),
      label: Calendar.strftime(timestamp, "%Y-%m-%d %H:%M:%S")
    }

    ~H"""
    <time datetime={@iso} title={@ago}>{@label}</time>
    """
  end

  def event_type("warn") do
    assigns = %{}

    ~H"""
    <span class="log-level log-level--warn">warn</span>
    """
  end

  def event_type(event_type) when event_type in ~w(failed error) do
    assigns = %{event_type: event_type}

    ~H"""
    <span class="log-level log-level--error">{@event_type}</span>
    """
  end

  def event_type(event_type), do: event_type

  def send_recv("SMTP"), do: "<-"
  def send_recv(_), do: "->"

  @doc "The first non-empty failure text of the event, or nil."
  def error_msg(%{raw: raw}) when is_map(raw) do
    [
      get_in(raw, ["delivery-status", "message"]),
      get_in(raw, ["delivery-status", "description"]),
      raw["reason"]
    ]
    |> Enum.find(&(is_binary(&1) and String.trim(&1) != ""))
  end

  def error_msg(_), do: nil

  def stored_message_url(message_id) do
    config = ExAws.Config.new(:s3)
    bucket = Application.get_env(:ex_aws, :bucket)
    base_dir = Application.get_env(:ex_aws, :raw_path)
    file_name = "#{message_id}.json"
    file_path = Path.join(base_dir, file_name)
    opts = []

    case ExAws.S3.presigned_url(config, :get, bucket, file_path, opts) do
      {:ok, url} -> url
      _ -> ""
    end
  end

  def pretty_raw(raw) do
    html =
      raw
      |> Jason.encode_to_iodata!()
      |> Jason.Formatter.pretty_print()

    assigns = %{html: html}

    ~H"""
    <code id="raw-json" style="white-space: break-spaces">{@html}</code>
    """
  end

  def list_attachments(%{"message" => %{"attachments" => atts}}) when atts != [] do
    atts = Enum.map(atts, &Map.get(&1, "filename", ""))

    assigns = %{attachments: atts}

    ~H"""
    <div class="text-dim" style="font-style: italic;">
      Note: listing belows shows filenames only, no links to the files available.
    </div>
    <ul style="padding:0;">
      <%= for a <- @attachments do %>
        <li>{a}</li>
      <% end %>
    </ul>
    """
  end

  def list_attachments(_), do: "none"

  def cbo_accounts(accounts), do: Enum.map(accounts, &{&1.domain, &1.id})

  @doc """
  The path to the events with one more filter. It keeps the other filters of
  the current page and replaces a filter on the same field.
  """
  def filter_path(%Flop.Meta{flop: flop}, field, op, value) do
    filters =
      flop.filters
      |> Enum.reject(&(&1.field == field))
      |> Enum.map(&{&1.field, &1.op, &1.value})
      |> Kernel.++([{field, op, value}])

    events_path(filters: filter_params(filters), first: flop.first, last: flop.last)
  end

  @doc "The path to the events with the current filters, without the filters on `field`."
  def remove_filter_path(%Flop.Meta{flop: flop}, field) do
    filters =
      flop.filters
      |> Enum.reject(&(&1.field == field))
      |> Enum.map(&{&1.field, &1.op, &1.value})

    events_path(filters: filter_params(filters), first: flop.first, last: flop.last)
  end

  @doc "The value of the filter on `field`, or nil."
  def filter_value(%Flop.Meta{flop: flop}, field),
    do: Enum.find_value(flop.filters, &(&1.field == field && &1.value))

  @doc "The path to all events of one message."
  def message_events_path(message_id),
    do: events_path(filters: filter_params([{:message_id, :==, message_id}]))

  @page_sizes [50, 100, 250]

  def page_sizes(), do: @page_sizes

  @doc "The path to the first page with another page size, with the same filters."
  def page_size_path(%Flop.Meta{flop: flop}, page_size) do
    filters = Enum.map(flop.filters, &{&1.field, &1.op, &1.value})
    events_path(filters: filter_params(filters), first: page_size)
  end

  @doc "The path to the CSV export of the events with the current filters."
  def export_path(%Flop.Meta{flop: flop}) do
    filters = Enum.map(flop.filters, &{&1.field, &1.op, &1.value})
    query = Plug.Conn.Query.encode([filters: filter_params(filters)], &query_value/1)
    ~p"/events/export.csv" <> "?" <> query
  end

  @doc "The page size of the current page."
  def page_size(%Flop.Meta{flop: flop}),
    do: flop.first || flop.last || Application.get_env(:mailgun_logger, :page_size)

  defp filter_params(filters) do
    filters
    |> Enum.with_index()
    |> Map.new(fn {{field, op, value}, index} ->
      {to_string(index), %{field: field, op: op, value: value}}
    end)
  end

  @doc """
  Builds the events path for the pagination links. Flop.Phoenix sets
  `first` or `last` to nil when the page size is the default, and a
  nil value would end up as an empty query parameter.
  """
  def events_path(params) do
    query =
      params
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Plug.Conn.Query.encode(&query_value/1)

    ~p"/events" <> "?" <> query
  end

  # A time filter value is a NaiveDateTime; write it like the datetime-local input does.
  defp query_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp query_value(value), do: to_string(value)
end
