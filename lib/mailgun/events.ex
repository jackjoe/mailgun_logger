defmodule Mailgun.Events do
  @moduledoc """
  Interfacing the Mailgun API
  """

  alias Mailgun.Client
  alias MailgunLogger.Event
  alias MailgunLogger.Events
  alias ExAws.S3

  require Logger

  @chunk_size 10
  @chunk_timeout 25_000

  @doc """
  Get events.
  [api docs](https://documentation.mailgun.com/en/latest/api-events.html#events)
  """
  def get_events(%Client{} = client, opts \\ %{}) do
    Client.get(client, "/DOMAIN/events?" <> URI.encode_query(opts))
  end

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
        save_stored_message(event.api_id, stored_message)

        case Events.has_stored_message(event) do
          {:ok, event} -> event
          _ -> event
        end
    end
  end

  # Store on S3
  defp save_stored_message(api_id, stored_message) do
    bucket()
    |> S3.put_object(file_path(api_id), Jason.encode!(stored_message))
    |> ExAws.request!()
  end

  def get_stored_message(event) do
    bucket = bucket()

    ExAws.S3.download_file(bucket, file_path(event), :memory)
    |> ExAws.stream!()
    |> Enum.join("")
    |> Jason.decode!()
  end

  def get_stored_message_content(event) do
    msg = get_stored_message(event)
    content_type = Map.get(msg, "Content-Type", "")

    if String.contains?(content_type, "text/plain") do
      Map.get(msg, "body-plain", "")
    else
      Map.get(msg, "body-html", "")
    end
  end

  def file_path(%{api_id: api_id}), do: file_path(api_id)
  def file_path(api_id), do: Path.join(base_dir(), file_name(api_id))
  def file_name(api_id), do: "#{api_id}.json"
  def base_dir(), do: Application.get_env(:ex_aws, :raw_path)
  def bucket(), do: Application.get_env(:ex_aws, :bucket)

  defp build_stored_message_url(client, "https://" <> r), do: "https://api:#{client.api_key}@#{r}"
  defp build_stored_message_url(_, url), do: url
end
