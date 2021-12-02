defmodule Pager.Page do
  defstruct [
    :page_number,
    :page_size,
    :next,
    :previous,
    :total_entries,
    :total_pages,
    entries: []
  ]

  @type t :: %__MODULE__{
          entries: list(),
          page_number: pos_integer(),
          page_size: integer(),
          next: integer(),
          previous: integer(),
          total_entries: integer(),
          total_pages: pos_integer()
        }

  defimpl Enumerable do
    @spec count(Pager.Page.t()) :: {:error, Enumerable.Pager.Page}
    def count(_page), do: {:error, __MODULE__}

    @spec member?(Pager.Page.t(), term) :: {:error, Enumerable.Pager.Page}
    def member?(_page, _value), do: {:error, __MODULE__}

    @spec reduce(Pager.Page.t(), Enumerable.acc(), Enumerable.reducer()) ::
            Enumerable.result()
    def reduce(%Pager.Page{entries: entries}, acc, fun), do: Enumerable.reduce(entries, acc, fun)

    @spec slice(Pager.Page.t()) :: {:error, Enumerable.Pager.Page}
    def slice(_page), do: {:error, __MODULE__}
  end

  defimpl Collectable do
    @spec into(Pager.Page.t()) ::
            {term, (term, Collectable.command() -> Pager.Page.t() | term)}
    def into(original) do
      original_entries = original.entries
      impl = Collectable.impl_for(original_entries)
      {_, entries_fun} = impl.into(original_entries)

      fun = fn page, command ->
        %{page | entries: entries_fun.(page.entries, command)}
      end

      {original, fun}
    end
  end
end
