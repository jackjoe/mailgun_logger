defmodule MailgunLoggerWeb.PagingHelpers do
  use Phoenix.HTML

  def sort_link(conn, _page, field, name, opts \\ []) do
    current_url = current_uri(conn)
    queries = URI.decode_query(current_url.query || "")

    queries =
      queries
      |> Map.merge(%{"sort" => field})
      |> Map.merge(%{"order" => reverse_order(queries["order"])})

    new_url = URI.to_string(%URI{current_url | query: URI.encode_query(queries)})

    link(name, Keyword.merge([to: new_url], opts))
  end

  def paging_links(conn, page) do
    queries =
      URI.decode_query(current_uri(conn).query || "")
      |> Map.delete("page")
      |> Enum.map(fn {key, value} -> {:"#{key}", value} end)

    Scrivener.HTML.pagination_links(page, queries)
  end

  defp current_uri(conn) do
    (MailgunLoggerWeb.Router.Helpers.url(conn) <>
       conn.request_path <> "?" <> URI.encode_query(conn.params))
    |> URI.parse()
  end

  defp reverse_order(prev) do
    case prev do
      "asc" -> "desc"
      "desc" -> "asc"
      _ -> "asc"
    end
  end

  def scrivener_format_params(params, defaults \\ %{}) do
    order = (params["order"] || (defaults["order"] || "asc")) |> String.to_atom()
    page_size = params["page_size"] || (defaults["page_size"] || 100)

    params
    |> Map.merge(%{"page_size" => page_size, "order" => order})
    |> Map.merge(defaults)
  end
end
