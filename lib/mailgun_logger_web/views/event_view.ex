defmodule MailgunLoggerWeb.EventView do
  use MailgunLoggerWeb, :view
  @moduledoc false

  def subject(%{message_subject: nil}), do: ""
  def subject(%{message_subject: ""}), do: ""

  def subject(%{message_subject: subject}) do
    case String.length(subject) > 20 do
      true -> "#{subject |> String.slice(0, 20) |> String.trim_trailing()}..."
      false -> subject
    end
  end

  def event_name(name) when name in ~w(delivered failed accepted opened) do
    assigns = %{name: name}

    ~H"""
    <span class={"log-event log-event--#{@name}"}><%= @name %></span>
    """
  end

  def event_name(event_name), do: event_name

  def event_type("warn") do
    assigns = %{}

    ~H"""
    <span class="log-level log-level--warn">warn</span>
    """
  end

  def event_type(event_type) when event_type in ~w(failed error) do
    assigns = %{event_type: event_type}

    ~H"""
    <span class="log-level log-level--error"><%= @event_type %></span>
    """
  end

  def event_type(event_type), do: event_type

  def send_recv("SMTP"), do: "<-"
  def send_recv(_), do: "->"

  def error_msg(%{raw: %{"delivery-status" => %{"message" => msg}}}), do: msg
  def error_msg(_), do: "-"

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
    <code style="white-space: break-spaces">
      <%= @html %>
    </code>
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
        <li><%= a %></li>
      <% end %>
    </ul>
    """
  end

  def list_attachments(_), do: "none"

  def cbo_accounts(accounts), do: Enum.map(accounts, &{&1.domain, &1.id})
end
