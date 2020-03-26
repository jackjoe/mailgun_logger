defmodule Pager.Config do
  defstruct [:page_size]

  @type t :: %__MODULE__{}
end

defmodule Pager do
  import Ecto.Query

  alias Pager.Page
  alias Pager.Config
  # For now just directly use our Repo untill
  # smart people make this configurable like Scrivener
  alias MailgunLogger.Repo

  @moduledoc false

  @spec paginate(Ecto.Query.t(), any, Config.t()) :: Page.t()
  def paginate(query, module, %{
        "page_size" => page_size,
        "page" => page
      }) do
    next_id = page

    {entries, next, previous} = entries(query, Repo, page_size, next_id)

    %Page{
      page_size: page_size,
      entries: entries,
      next: next,
      previous: previous
    }
  end

  defp entries(query, repo, page_size, nil) do
    first_item(query, repo)
    |> case do
      nil -> {[], 0, 0}
      next_id -> entries(query, repo, page_size, next_id)
    end
  end

  defp entries(query, repo, page_size, next_id) do
    entries =
      query
      |> where([e], e.id <= ^next_id)
      |> limit(^page_size + 1)
      |> repo.all()

    {entries, next, previous} =
      case length(entries) > page_size do
        false ->
          {entries, 0, 0}

        true ->
          {next, entries} = List.pop_at(entries, -1)
          {previous, entries} = List.pop_at(entries, 1)
          {entries, Map.get(next || %{}, :id, 0), Map.get(previous || %{}, :id, 0)}
      end

    {entries, next, previous}
  end

  defp total_entries(query, repo) do
    query
    |> exclude(:preload)
    |> exclude(:select)
    |> exclude(:order_by)
    |> order_by([e], desc: e.id)
    |> limit(1)
    |> select([e], e.id)
    |> Repo.all()
    |> case do
      [] -> 0
      [id] -> id
    end
  end

  defp first_item(query, repo) do
    query
    |> exclude(:preload)
    |> exclude(:select)
    |> exclude(:order_by)
    |> order_by([e], desc: e.id)
    |> limit(1)
    |> select([e], e.id)
    |> Repo.all()
    |> case do
      [] -> nil
      [id] -> id
    end
  end
end
