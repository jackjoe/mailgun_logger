defmodule MailgunLoggerWeb.PagingHelpers do
  use PhoenixHTMLHelpers

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

  # def format_pager_params(params, defaults \\ %{}) do
  #   page_size =
  #     params["page_size"] ||
  #       (defaults["page_size"] ||
  #          String.to_integer(Application.get_env(:mailgun_logger, :ml_pagesize)))

  #   page = params["page"] || (defaults["page"] || nil)

  #   params
  #   |> Map.merge(%{"page_size" => page_size})
  #   |> Map.merge(%{"page" => page})
  #   |> Map.merge(defaults)
  # end

  # def paging_links(conn, page) do
  #   queries =
  #     (current_uri(conn).query || "")
  #     |> URI.decode_query()
  #     |> Map.delete("page")
  #     |> Enum.map(fn {key, value} -> {:"#{key}", value} end)

  #   Scrivener.HTML.pagination_links(page, queries)
  # end

  # def scrivener_format_params(params, defaults \\ %{}) do
  #   order =
  #     try do
  #       (params["order"] || (defaults["order"] || "asc")) |> String.to_existing_atom()
  #     rescue
  #       ArgumentError -> "asc"
  #     end

  #   page_size = params["page_size"] || (defaults["page_size"] || 100)

  #   params
  #   |> Map.merge(%{"page_size" => page_size, "order" => order})
  #   |> Map.merge(defaults)
  # end
end
