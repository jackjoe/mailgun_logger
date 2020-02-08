defmodule Slacker do
  @moduledoc """
  Sends simple HTTP(S) request to Slack API to display short message on your channel.
  Remember to configure your webhook at config/config.exs:
    slack_hook: "https://hooks.slack.com/services/*/*/*"
  """

  def new() do
    %{channel: "app-bot", icon_emoji: ":rage1:", text: "test", url: get_url()}
  end

  def channel(slack, channel) do
    Map.merge(slack, %{channel: channel})
  end

  def icon(slack, icon) do
    Map.merge(slack, %{icon_emoji: icon})
  end

  def message(slack, message) do
    Map.merge(slack, %{text: message})
  end

  @doc "Build Slack url"
  def url(slack, url) do
    Map.merge(slack, %{url: url})
  end

  @doc """
  Sends message to channel with webhook url.
  """
  def send(slack) do
    HTTPoison.post(slack.url, get_content(slack))
  end

  @doc """
  Sends asynchronous message to channel with webhook url.
  """
  def send_async(slack) do
    case slack.url do
      nil -> IO.puts("no slack url")
      _ -> HTTPoison.post(slack.url, get_content(slack), [], hackney: [stream_to: self()])
    end
  end

  defp get_url do
    Application.get_env(:mailgun_logger, :slack_hook)
  end

  defp get_content(slack),
    do: """
    {
      "icon_emoji": "#{slack.icon_emoji}",
      "channel": "##{slack.channel}",
      "text": "#{slack.text}"
    }
    """
end
