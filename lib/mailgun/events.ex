defmodule Mailgun.Events do
  @moduledoc """
  Interfacing the Mailgun API
  """

  alias Mailgun.Client
  require Logger

  @doc """
  Get events.
  [api docs](https://documentation.mailgun.com/en/latest/api-events.html#events)
  """
  def get_events(%Client{} = client, opts \\ %{}) do
    Client.get(client, "/DOMAIN/events?" <> URI.encode_query(opts))
  end
end
