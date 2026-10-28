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

  @doc """
  Retrieve the actual sent message from Mailgun and store it on S3.
  `has_stored_message` is true only when the message is on S3.
  """
  def get_stored_message(client, %Event{} = event) do
    if Application.get_env(:mailgun_logger, :store_messages) do
      stored? =
        case fetch_stored_message(client, event) do
          {:ok, stored_message} -> save_stored_message(event.api_id, stored_message) == :ok
          {:error, _} -> false
        end

      case Events.set_has_stored_message(event, stored?) do
        {:ok, event} -> event
        _ -> event
      end
    else
      event
    end
  end

  # Mailgun keeps the message for a couple of days only.
  defp fetch_stored_message(client, %Event{raw: raw} = event) do
    case get_in(raw, ["storage", "url"]) do
      nil ->
        {:error, :no_storage_url}

      url ->
        case Client.get(client, url) do
          %{} = stored_message ->
            {:ok, stored_message}

          error ->
            Logger.warning("Failed to get stored message #{event.api_id}: #{inspect(error)}")
            {:error, error}
        end
    end
  end

  # Store on S3
  defp save_stored_message(api_id, stored_message) do
    case bucket()
         |> S3.put_object(file_path(api_id), Jason.encode!(stored_message))
         |> ExAws.request() do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to save stored message #{api_id} to S3: #{inspect(reason)}")
        :error
    end
  end

  defp read_stored_message(%Event{has_stored_message: false}), do: {:error, :not_stored}

  defp read_stored_message(%Event{} = event) do
    case bucket() |> S3.get_object(file_path(event)) |> ExAws.request() do
      {:ok, %{body: body}} ->
        Jason.decode(body)

      {:error, reason} ->
        Logger.warning(
          "Failed to read stored message #{event.api_id} from S3: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  @doc "The body of the sent message, from S3 or else from Mailgun."
  def get_stored_message_content(%Event{} = event, %Client{} = client) do
    with {:error, _} <- read_stored_message(event),
         {:error, _} <- fetch_stored_message(client, event) do
      {:error, :not_found}
    else
      {:ok, stored_message} -> {:ok, message_body(stored_message)}
    end
  end

  defp message_body(stored_message) do
    content_type = Map.get(stored_message, "Content-Type", "")

    if String.contains?(content_type, "text/plain") do
      Map.get(stored_message, "body-plain", "")
    else
      Map.get(stored_message, "body-html", "")
    end
  end

  def file_path(%{api_id: api_id}), do: file_path(api_id)
  def file_path(api_id), do: Path.join(base_dir(), file_name(api_id))
  def file_name(api_id), do: "#{api_id}.json"
  def base_dir(), do: Application.get_env(:ex_aws, :raw_path)
  def bucket(), do: Application.get_env(:ex_aws, :bucket)
end
