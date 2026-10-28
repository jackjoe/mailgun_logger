defmodule Mailgun.EventsTest do
  use MailgunLogger.DataCase

  # The error paths log on purpose; keep that out of the test output.
  @moduletag :capture_log

  alias Mailgun.Client
  alias MailgunLogger.Event

  @client Client.new("key-test", "mg.example.com", true)
  @storage_url "https://storage-europe-west1.api.mailgun.net/v3/domains/mg.example.com/messages/key1"

  setup do
    store_messages = Application.get_env(:mailgun_logger, :store_messages)
    Application.put_env(:mailgun_logger, :store_messages, true)
    on_exit(fn -> Application.put_env(:mailgun_logger, :store_messages, store_messages) end)
  end

  defp stored_event(attrs \\ []) do
    insert(:event, [api_id: "api_1", raw: %{"storage" => %{"url" => @storage_url}}] ++ attrs)
  end

  defp stub_s3_get(status, body) do
    Req.Test.stub(ExAws, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/test-bucket/messages/api_1.json"
      Plug.Conn.send_resp(conn, status, body)
    end)
  end

  describe "get_stored_message/2" do
    test "stores a fetched message on S3" do
      test = self()
      event = stored_event()

      Req.Test.stub(Client, &Req.Test.json(&1, %{"body-html" => "<p>Hi</p>"}))

      Req.Test.stub(ExAws, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        send(test, {:s3, conn.method, conn.host, conn.request_path, body})
        Plug.Conn.send_resp(conn, 200, "")
      end)

      assert %Event{has_stored_message: true} = Mailgun.Events.get_stored_message(@client, event)
      assert Repo.get!(Event, event.id).has_stored_message

      assert_received {:s3, "PUT", host, "/test-bucket/messages/api_1.json", body}
      assert host =~ "amazonaws.com"
      assert Jason.decode!(body) == %{"body-html" => "<p>Hi</p>"}
    end

    test "does not fetch or flag the message when storing is off" do
      Application.put_env(:mailgun_logger, :store_messages, false)
      event = stored_event()

      Req.Test.stub(Client, fn _conn -> flunk("fetched the message") end)

      assert %Event{has_stored_message: false} =
               Mailgun.Events.get_stored_message(@client, event)

      refute Repo.get!(Event, event.id).has_stored_message
    end

    test "clears the flag when the upload to S3 fails" do
      event = stored_event(has_stored_message: true)

      Req.Test.stub(Client, &Req.Test.json(&1, %{"body-html" => "<p>Hi</p>"}))
      Req.Test.stub(ExAws, &Plug.Conn.send_resp(&1, 403, "<Error>AccessDenied</Error>"))

      assert %Event{has_stored_message: false} =
               Mailgun.Events.get_stored_message(@client, event)

      refute Repo.get!(Event, event.id).has_stored_message
    end

    test "does not flag the message when Mailgun does not return it" do
      event = stored_event()

      Req.Test.stub(Client, &Req.Test.json(Plug.Conn.put_status(&1, 404), %{"message" => "x"}))
      Req.Test.stub(ExAws, fn _conn -> flunk("stored a missing message") end)

      assert %Event{has_stored_message: false} =
               Mailgun.Events.get_stored_message(@client, event)
    end
  end

  describe "get_stored_message_content/2" do
    test "reads a stored message from S3" do
      event = stored_event(has_stored_message: true)

      stub_s3_get(
        200,
        Jason.encode!(%{"Content-Type" => "text/html", "body-html" => "<p>Hi</p>"})
      )

      Req.Test.stub(Client, fn _conn -> flunk("fetched the message from Mailgun") end)

      assert Mailgun.Events.get_stored_message_content(event, @client) == {:ok, "<p>Hi</p>"}
    end

    test "reads the plain body of a text message" do
      event = stored_event(has_stored_message: true)
      stub_s3_get(200, Jason.encode!(%{"Content-Type" => "text/plain", "body-plain" => "Hi"}))

      assert Mailgun.Events.get_stored_message_content(event, @client) == {:ok, "Hi"}
    end

    test "falls back to Mailgun when the message is not on S3" do
      event = stored_event(has_stored_message: true)
      stub_s3_get(404, "<Error><Code>NoSuchKey</Code></Error>")
      Req.Test.stub(Client, &Req.Test.json(&1, %{"body-html" => "<p>From Mailgun</p>"}))

      assert Mailgun.Events.get_stored_message_content(event, @client) ==
               {:ok, "<p>From Mailgun</p>"}
    end

    test "fetches from Mailgun when the message was never stored" do
      event = stored_event()
      Req.Test.stub(ExAws, fn _conn -> flunk("read S3 for a message that was never stored") end)
      Req.Test.stub(Client, &Req.Test.json(&1, %{"body-html" => "<p>From Mailgun</p>"}))

      assert Mailgun.Events.get_stored_message_content(event, @client) ==
               {:ok, "<p>From Mailgun</p>"}
    end

    test "returns an error when neither S3 nor Mailgun has the message" do
      event = stored_event(has_stored_message: true)
      stub_s3_get(404, "<Error><Code>NoSuchKey</Code></Error>")
      Req.Test.stub(Client, &Req.Test.json(Plug.Conn.put_status(&1, 404), %{"message" => "x"}))

      assert Mailgun.Events.get_stored_message_content(event, @client) == {:error, :not_found}
    end

    test "returns an error for an event without a storage URL" do
      event = insert(:event)
      assert Mailgun.Events.get_stored_message_content(event, @client) == {:error, :not_found}
    end
  end
end
