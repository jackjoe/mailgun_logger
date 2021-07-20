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
  require Logger

  @base_url "https://api:API_KEY@api.mailgun.net/v3"
  @base_eu_url "https://api:API_KEY@api.eu.mailgun.net/v3"

  @ttl 60_000
  @request_opts [recv_timeout: @ttl, timeout: @ttl]

  @spec new(MailgunLogger.Account.t()) :: Client.t()
  def new(%MailgunLogger.Account{} = account),
    do: new(account.api_key, account.domain, account.is_eu)

  @spec new(String.t(), String.t(), boolean()) :: Client.t()
  def new(api_key, domain, is_eu), do: %Client{api_key: api_key, domain: domain, is_eu: is_eu}

  def get(client, path), do: _request(:get, client, url(client, path))

  defp get_page(client, url, acc \\ []) do
    # Logger.info "Mailgun client :: get_page :: #{url}"
    Logger.debug(Atom.to_string(:get) <> " - " <> url)

    :get
    |> HTTPoison.request!(url, "", [], request_opts(client))
    |> handle_response(client, acc)
  end

  defp _request(method, client, url, body \\ "") do
    Logger.debug(Atom.to_string(method) <> " - " <> url)

    method
    |> HTTPoison.request!(url, body, [], request_opts(client))
    |> handle_response(client)
  end

  @spec request_opts(Client.t()) :: Keyword.t()
  def request_opts(%Client{} = client),
    do: @request_opts ++ [hackney: [basic_auth: {"api", client.api_key}]]

  @spec handle_response(HTTPoison.Response.t(), Client.t(), map()) :: binary
  def handle_response(response, client, acc \\ [])

  def handle_response(
        %HTTPoison.Response{status_code: 200, body: body, headers: headers},
        client,
        acc
      ) do
    body
    |> process_body(headers)
    |> handle_paging(client, acc)
  end

  def handle_response(%HTTPoison.Response{status_code: 400, body: body}, _, _) do
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

  def handle_response(%HTTPoison.Response{status_code: status_code, body: body}, _, _),
    do: {:error, status_code, body}

  def handle_response(%HTTPoison.Error{reason: reason}, _, _) do
    Logger.error(reason)
    {:error, reason}
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
    base_url = base_url |> String.replace("API_KEY", client.api_key)
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

  defp get_header(headers, header), do: Map.new(headers) |> Map.get(header)
end
