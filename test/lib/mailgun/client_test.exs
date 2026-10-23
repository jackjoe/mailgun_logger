defmodule Mailgun.ClientTest do
  use ExUnit.Case, async: true

  alias Mailgun.Client

  @client Client.new("key-test", "mg.example.com", true)

  defp json(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, Jason.encode!(body))
  end

  defp page_url(page), do: "https://api.eu.mailgun.net/v3/mg.example.com/events/#{page}"

  test "gets a page of events from the EU API with basic auth" do
    test = self()

    Req.Test.stub(Client, fn conn ->
      send(
        test,
        {:request, conn.host, conn.request_path, Plug.Conn.get_req_header(conn, "authorization")}
      )

      json(conn, 200, %{"items" => [%{"id" => "a"}], "paging" => %{}})
    end)

    assert Client.get(@client, "/DOMAIN/events?limit=10") == [%{"id" => "a"}]

    assert_received {:request, "api.eu.mailgun.net", "/v3/mg.example.com/events",
                     ["Basic " <> credentials]}

    assert Base.decode64!(credentials) == "api:key-test"
  end

  test "uses the US API for a US account" do
    test = self()

    Req.Test.stub(Client, fn conn ->
      send(test, {:host, conn.host})
      json(conn, 200, %{"items" => []})
    end)

    assert Client.get(Client.new("key-test", "mg.example.com", false), "/DOMAIN/events") == []
    assert_received {:host, "api.mailgun.net"}
  end

  test "follows the next page until a page is empty" do
    Req.Test.stub(Client, fn conn ->
      case conn.request_path do
        "/v3/mg.example.com/events" ->
          json(conn, 200, %{
            "items" => [%{"id" => "a"}],
            "paging" => %{"next" => page_url("p2"), "last" => page_url("p9")}
          })

        "/v3/mg.example.com/events/p2" ->
          json(conn, 200, %{
            "items" => [%{"id" => "b"}],
            "paging" => %{"next" => page_url("p3"), "last" => page_url("p9")}
          })

        "/v3/mg.example.com/events/p3" ->
          json(conn, 200, %{
            "items" => [],
            "paging" => %{"next" => page_url("p4"), "last" => page_url("p9")}
          })
      end
    end)

    events = Client.get(@client, "/DOMAIN/events")
    assert events |> Enum.map(& &1["id"]) |> Enum.sort() == ["a", "b"]
  end

  test "stops at the last page" do
    Req.Test.stub(Client, fn conn ->
      case conn.request_path do
        "/v3/mg.example.com/events" ->
          json(conn, 200, %{
            "items" => [%{"id" => "a"}],
            "paging" => %{"next" => page_url("p2"), "last" => page_url("p2")}
          })
      end
    end)

    assert Client.get(@client, "/DOMAIN/events") == [%{"id" => "a"}]
  end

  test "returns the message of a 400 response" do
    Req.Test.stub(Client, &json(&1, 400, %{"error" => %{"message" => "bad range"}}))
    assert Client.get(@client, "/DOMAIN/events") == {:error, "bad range"}
  end

  test "returns the status and body of another error response" do
    Req.Test.stub(Client, &json(&1, 401, %{"message" => "Forbidden"}))
    assert {:error, 401, body} = Client.get(@client, "/DOMAIN/events")
    assert body =~ "Forbidden"
  end

  test "returns a network error instead of raising" do
    Req.Test.stub(Client, &Req.Test.transport_error(&1, :econnrefused))

    assert {:error, %Req.TransportError{reason: :econnrefused}} =
             Client.get(@client, "/DOMAIN/events")
  end

  test "gets a stored message from an absolute storage URL" do
    test = self()

    Req.Test.stub(Client, fn conn ->
      send(
        test,
        {:request, conn.host, conn.request_path, Plug.Conn.get_req_header(conn, "authorization")}
      )

      json(conn, 200, %{"subject" => "Hello"})
    end)

    url = "https://storage-europe-west1.api.mailgun.net/v3/domains/mg.example.com/messages/key1"
    assert Client.get(@client, url) == %{"subject" => "Hello"}

    assert_received {:request, "storage-europe-west1.api.mailgun.net",
                     "/v3/domains/mg.example.com/messages/key1", ["Basic " <> _]}
  end

  test "returns a body that is not JSON as text" do
    Req.Test.stub(Client, &Plug.Conn.send_resp(&1, 200, "plain text"))
    assert Client.get(@client, "/DOMAIN/events") == "plain text"
  end
end
