defmodule Mailgun.Events do
  @moduledoc """
  Interfacing the Mailgun API
  """

  alias Mailgun.Client
  alias MailgunLogger.Event
  alias MailgunLogger.Events
  require Logger

  @chunk_size 10
  @chunk_timeout 5_000

  @doc """
  Get events.
  [api docs](https://documentation.mailgun.com/en/latest/api-events.html#events)
  """
  def get_events(%Client{} = client, opts \\ %{}),
    do: Client.get(client, "/DOMAIN/events?" <> URI.encode_query(opts))

  @doc "Retrieve the actual sent messages"
  def get_stored_messages(%Client{} = client, events) do
    events
    |> Enum.chunk_every(@chunk_size)
    |> Enum.map(fn chunk ->
      chunk
      |> Enum.map(&Task.async(fn -> get_stored_message(client, &1) end))
      |> Enum.map(&Task.await(&1, @chunk_timeout))
    end)
    |> List.flatten()
  end

  @doc "Retrieve the actual sent message"
  def get_stored_message(client, %Event{raw: raw} = event) do
    case get_in(raw, ["storage", "url"]) do
      nil ->
        event

      url ->
        url = build_stored_message_url(client, url)
        stored_message = Client.get(client, url)

        case Events.save_stored_message(event, stored_message) do
          {:ok, event} -> event
          _ -> event
        end
    end
  end

  defp build_stored_message_url(client, "https://" <> r), do: "https://api:#{client.api_key}@#{r}"
  defp build_stored_message_url(_, url), do: url
end
