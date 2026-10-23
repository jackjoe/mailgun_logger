defmodule Mailgun.EventsTest do
  use MailgunLogger.DataCase

  alias Mailgun.Client
  alias MailgunLogger.Event

  @client Client.new("key-test", "mg.example.com", true)
  @storage_url "https://storage-europe-west1.api.mailgun.net/v3/domains/mg.example.com/messages/key1"

  setup do
    store_messages = Application.get_env(:mailgun_logger, :store_messages)
    Application.put_env(:mailgun_logger, :store_messages, true)
    on_exit(fn -> Application.put_env(:mailgun_logger, :store_messages, store_messages) end)
  end

  test "stores a fetched message on S3" do
    test = self()
    event = insert(:event, api_id: "api_1", raw: %{"storage" => %{"url" => @storage_url}})

    Req.Test.stub(Client, &Req.Test.json(&1, %{"body-html" => "<p>Hi</p>"}))

    Req.Test.stub(ExAws, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      send(test, {:s3, conn.method, conn.host, conn.request_path, body})
      Plug.Conn.send_resp(conn, 200, "")
    end)

    assert %Event{has_stored_message: true} = Mailgun.Events.get_stored_message(@client, event)

    assert_received {:s3, "PUT", host, "/test-bucket/messages/api_1.json", body}
    assert host =~ "amazonaws.com"
    assert Jason.decode!(body) == %{"body-html" => "<p>Hi</p>"}
  end

  test "reads a stored message from S3" do
    body = Jason.encode!(%{"Content-Type" => "text/html", "body-html" => "<p>Hi</p>"})

    Req.Test.stub(ExAws, fn conn ->
      case conn.method do
        "HEAD" ->
          conn
          |> Plug.Conn.put_resp_header("content-length", Integer.to_string(byte_size(body)))
          |> Plug.Conn.send_resp(200, "")

        "GET" ->
          Plug.Conn.send_resp(conn, 200, body)
      end
    end)

    assert Mailgun.Events.get_stored_message_content(%{api_id: "api_1"}) == "<p>Hi</p>"
  end
end
