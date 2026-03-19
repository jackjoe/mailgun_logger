defmodule MailgunLoggerWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by tests
  that require setting up a connection.
  Such tests rely on `Phoenix.ConnTest` and also import
  other functionality to make it easier to build common
  data structures and query the data layer.
  """
  use ExUnit.CaseTemplate
  using do
    quote do
      # The default endpoint for testing
      @endpoint MailgunLoggerWeb.Endpoint
      import Plug.Conn
      import Phoenix.ConnTest
      import MailgunLogger.Factory
      import MailgunLogger.DataCase
      alias MailgunLogger.Repo
      alias MailgunLoggerWeb.Router.Helpers, as: Routes
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
