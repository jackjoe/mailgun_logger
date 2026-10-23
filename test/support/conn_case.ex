defmodule MailgunLoggerWeb.ConnCase do
  @moduledoc """
  This module defines the setup for tests requiring
  a connection to the endpoint.

  Every test runs inside a transaction which is reset
  at the beginning of the test unless the test case is
  marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint MailgunLoggerWeb.Endpoint

      use MailgunLoggerWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import MailgunLogger.Factory
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MailgunLogger.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(MailgunLogger.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
