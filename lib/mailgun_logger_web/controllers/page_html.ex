defmodule MailgunLoggerWeb.PageHTML do
  @moduledoc false
  use MailgunLoggerWeb, :html

  embed_templates("page_html/*")

  # The order of the stacks in the chart, from the bottom up.
  @chart_types ~w(delivered accepted opened clicked failed)

  @doc "The tiles at the top of the stats page: a count per type with a rate and a change."
  def stat_tiles(counts, previous) do
    count = &Map.get(counts, &1, 0)
    accepted = count.("accepted")
    delivered = count.("delivered")

    [
      {"Accepted", "accepted", nil},
      {"Delivered", "delivered", percentage(delivered, accepted) <> " of accepted"},
      {"Failed", "failed", percentage(count.("failed"), accepted) <> " of accepted"},
      {"Opened", "opened", percentage(count.("opened"), delivered) <> " opens per delivered"}
    ]
    |> Enum.map(fn {label, type, rate} ->
      %{
        label: label,
        type: type,
        count: count.(type),
        rate: rate,
        change: change(count.(type), Map.get(previous, type, 0))
      }
    end)
  end

  @doc "A share as a percentage with one decimal, or a dash without a base."
  def percentage(_part, 0), do: "–"
  def percentage(part, whole), do: :erlang.float_to_binary(part / whole * 100, decimals: 1) <> "%"

  @doc "The change of a count against the previous period."
  def change(0, 0), do: nil
  def change(_current, 0), do: "new"

  def change(current, previous) do
    percent = round((current - previous) / previous * 100)
    if percent >= 0, do: "+#{percent}%", else: "#{percent}%"
  end

  @doc """
  The path to the events that match the stats filters: optional event type and
  recipient, the account, and the time range.
  """
  def events_path(filters, from, to, account_id) do
    filters =
      filters ++
        [
          {:account_id, :==, account_id},
          {:timestamp, :>=, NaiveDateTime.to_iso8601(from)},
          {:timestamp, :<=, NaiveDateTime.to_iso8601(to)}
        ]

    query =
      filters
      |> Enum.reject(fn {_field, _op, value} -> is_nil(value) end)
      |> Enum.with_index()
      |> Map.new(fn {{field, op, value}, index} ->
        {to_string(index), %{field: field, op: op, value: value}}
      end)

    ~p"/events?#{%{filters: query}}"
  end

  @doc "The path to the stats page with another range or account."
  def stats_path(range, account_id) do
    ~p"/stats?#{Enum.reject([range: range, account_id: account_id], &is_nil(elem(&1, 1)))}"
  end

  attr(:volume, :list, required: true)
  attr(:bucket, :string, required: true)
  attr(:account_id, :any, required: true)

  @doc """
  A stacked bar chart of the events per hour or day, drawn as SVG. Each bar
  links to the events of its bucket.
  """
  def volume_chart(assigns) do
    # Close to the width of the page content, so the text keeps its size.
    width = 1360
    height = 260
    left = 44
    bottom = 24
    plot_width = width - left - 8
    plot_height = height - bottom - 8
    slot = plot_width / max(length(assigns.volume), 1)
    total = fn counts -> counts |> Map.values() |> Enum.sum() end
    max_total = assigns.volume |> Enum.map(&total.(&1.counts)) |> Enum.max(fn -> 0 end) |> max(1)
    scale = plot_height / max_total
    label_every = max(div(length(assigns.volume) + 11, 12), 1)

    bars =
      assigns.volume
      |> Enum.with_index()
      |> Enum.map(fn {%{at: at, counts: counts}, index} ->
        x = left + index * slot

        {segments, _} =
          Enum.map_reduce(stack(counts), 8 + plot_height, fn {type, count}, y ->
            h = count * scale
            {%{type: type, count: count, y: y - h, height: h}, y - h}
          end)

        %{
          x: x + slot * 0.15,
          width: slot * 0.7,
          at: at,
          label: if(rem(index, label_every) == 0, do: bucket_label(at, assigns.bucket)),
          title: bar_title(at, assigns.bucket, counts),
          href: events_path([], at, bucket_end(at, assigns.bucket), assigns.account_id),
          segments: segments
        }
      end)

    assigns =
      assign(assigns,
        width: width,
        height: height,
        left: left,
        top: 8,
        base: 8 + plot_height,
        max_total: max_total,
        empty?: Enum.all?(assigns.volume, &(&1.counts == %{})),
        bars: bars,
        types: @chart_types ++ ["other"]
      )

    ~H"""
    <div :if={@empty?} class="chart-empty">No events in this period.</div>
    <div :if={!@empty?} class="chart-scroll">
      <svg
        class="volume-chart"
        viewBox={"0 0 #{@width} #{@height}"}
        role="img"
        aria-label="Events per #{@bucket}"
      >
        <line class="grid" x1={@left} x2={@width} y1={@top} y2={@top} />
        <line class="grid" x1={@left} x2={@width} y1={(@top + @base) / 2} y2={(@top + @base) / 2} />
        <line class="axis" x1={@left} x2={@width} y1={@base} y2={@base} />
        <text class="tick" x={@left - 6} y={@top + 4} text-anchor="end">{@max_total}</text>
        <text
          :if={@max_total >= 2}
          class="tick"
          x={@left - 6}
          y={(@top + @base) / 2 + 4}
          text-anchor="end"
        >
          {div(@max_total, 2)}
        </text>
        <text class="tick" x={@left - 6} y={@base + 4} text-anchor="end">0</text>
        <a :for={bar <- @bars} href={bar.href} class="bar">
          <title>{bar.title}</title>
          <rect class="hit" x={bar.x} y={@top} width={bar.width} height={@base - @top} />
          <rect
            :for={segment <- bar.segments}
            class={"segment segment-#{segment.type}"}
            x={bar.x}
            y={segment.y}
            width={bar.width}
            height={segment.height}
          />
          <text
            :if={bar.label}
            class="tick"
            x={bar.x + bar.width / 2}
            y={@base + 16}
            text-anchor="middle"
          >
            {bar.label}
          </text>
        </a>
      </svg>
    </div>
    <ul :if={!@empty?} class="chart-legend">
      <li :for={type <- @types}><span class={"swatch segment-#{type}"}></span>{type}</li>
    </ul>
    """
  end

  defp stack(counts) do
    other = counts |> Map.drop(@chart_types) |> Map.values() |> Enum.sum()

    (Enum.map(@chart_types, &{&1, Map.get(counts, &1, 0)}) ++ [{"other", other}])
    |> Enum.reject(fn {_type, count} -> count == 0 end)
  end

  defp bucket_label(at, "hour"), do: Calendar.strftime(at, "%H:00")
  defp bucket_label(at, "day"), do: Calendar.strftime(at, "%b %d")

  defp bucket_end(at, "hour"), do: NaiveDateTime.add(at, 3599)
  defp bucket_end(at, "day"), do: NaiveDateTime.add(at, 86_399)

  defp bar_title(at, bucket, counts) do
    time =
      if bucket == "hour",
        do: Calendar.strftime(at, "%Y-%m-%d %H:00 UTC"),
        else: Calendar.strftime(at, "%Y-%m-%d")

    details = Enum.map_join(stack(counts), ", ", fn {type, count} -> "#{type} #{count}" end)
    if details == "", do: "#{time}: no events", else: "#{time}: #{details}"
  end
end
