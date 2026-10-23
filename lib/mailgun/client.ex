defmodule Mailgun.Client do
  @moduledoc "HTTP interface for the Mailgun API."

  require Logger

  defstruct [:api_key, :domain, :is_eu]

  @type t :: %__MODULE__{
          api_key: String.t(),
          domain: String.t(),
          is_eu: boolean
        }

  alias Mailgun.Client

  @base_url "https://api.mailgun.net/v3"
  @base_eu_url "https://api.eu.mailgun.net/v3"

  @ttl 60_000

  @spec new(MailgunLogger.Account.t()) :: Client.t()
  def new(%MailgunLogger.Account{} = account),
    do: new(account.api_key, account.domain, account.is_eu)

  @spec new(String.t(), String.t(), boolean()) :: Client.t()
  def new(api_key, domain, is_eu), do: %Client{api_key: api_key, domain: domain, is_eu: is_eu}

  def get(client, path), do: _request(:get, client, url(client, path))

  defp get_page(client, url, acc \\ []) do
    Logger.debug("get" <> " - " <> url)

    client
    |> request(:get, url)
    |> handle_response(client, acc)
  end

  defp _request(method, client, url) do
    Logger.debug("#{method} - #{url}")

    client
    |> request(method, url)
    |> handle_response(client)
  end

  # The body is decoded in process_body/2, which also accepts text/javascript.
  defp request(client, method, url) do
    [
      method: method,
      url: url,
      auth: {:basic, "api:" <> client.api_key},
      receive_timeout: @ttl,
      decode_body: false
    ]
    |> Keyword.merge(Application.get_env(:mailgun_logger, Client, [])[:req_options] || [])
    |> Req.request()
  end

  @spec handle_response(
          {:ok, Req.Response.t()} | {:error, Exception.t()} | term,
          Client.t(),
          list
        ) ::
          term
  def handle_response(response, client, acc \\ [])

  def handle_response(
        {:ok, %Req.Response{status: 200, body: body, headers: headers}},
        client,
        acc
      ) do
    body
    |> process_body(headers)
    |> handle_paging(client, acc)
  end

  def handle_response({:ok, %Req.Response{status: 400, body: body}}, _, _) do
    case Jason.decode!(body) do
      %{"error" => %{"message" => message}} ->
        Logger.error(message)
        {:error, message}

      _ ->
        reason = "unknown_400"
        Logger.error(reason)
        {:error, reason}
    end
  end

  def handle_response({:ok, %Req.Response{status: status, body: body}}, _, _),
    do: {:error, status, body}

  def handle_response({:error, %{__exception__: true} = exception}, _, _) do
    Logger.error("Mailgun request failed: " <> Exception.message(exception))
    {:error, exception}
  end

  def handle_response({:ok, %{"paging" => %{"next" => next}, "items" => items}}, client, acc) do
    client
    |> get_page(next)
    |> handle_response(client, items ++ acc)
  end

  def handle_response({:error, reason, _}, _, _), do: {:error, reason}
  def handle_response({:error, reason}, _, _), do: {:error, reason}
  def handle_response({:ok, %{"items" => items}}, _, acc), do: acc ++ items
  def handle_response({:ok, _resp}, _, acc), do: acc

  def handle_paging(
        %{"paging" => %{"next" => next, "last" => last}, "items" => items},
        client,
        acc
      )
      when next != last and items !== [] do
    get_page(client, next, items ++ acc)
  end

  def handle_paging(%{"items" => items}, _client, acc), do: acc ++ items
  def handle_paging(r, _, _), do: r

  def url(_, "http" <> _ = url), do: url
  def url(%Client{is_eu: true} = client, path), do: _url(@base_eu_url, client, path)
  def url(%Client{is_eu: false} = client, path), do: _url(@base_url, client, path)

  defp _url(base_url, client, path) do
    (base_url <> path) |> String.replace("DOMAIN", client.domain)
  end

  @doc """
  Process the response body. When it is JSON, check for paging and fecht recursive.
  """
  def process_body(body, headers) do
    content_type = get_header(headers, "Content-Type")

    case content_type =~ "application/json" || content_type =~ "text/javascript" do
      true -> Jason.decode!(body)
      false -> body
    end
  end

  # Req gives the headers as a map of lowercase names to lists of values.
  defp get_header(headers, header),
    do: headers |> Map.get(String.downcase(header), []) |> Enum.join(", ")
end
