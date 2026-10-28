defmodule MailgunLoggerTest do
  use MailgunLogger.DataCase

  # The error paths log on purpose; keep that out of the test output.
  @moduletag :capture_log

  alias MailgunLogger.Account

  defp raw_event(id) do
    %{
      "id" => id,
      "event" => "delivered",
      "timestamp" => 1_792_760_000.0,
      "recipient" => "to@example.com",
      "message" => %{"headers" => %{"from" => "from@example.com", "subject" => "Hi"}}
    }
  end

  defp reload(account), do: Repo.get!(Account, account.id)

  test "process_account saves a successful run" do
    account = insert(:account)

    Req.Test.stub(
      Mailgun.Client,
      &Req.Test.json(&1, %{"items" => [raw_event("e1"), raw_event("e2")]})
    )

    MailgunLogger.process_account(account)

    account = reload(account)
    assert account.last_run_status == "ok"
    assert account.last_run_event_count == 2
    assert account.last_run_error == nil
    assert DateTime.diff(DateTime.utc_now(), account.last_run_at) < 5
  end

  test "process_account saves the error of a 401 response" do
    account = insert(:account)

    Req.Test.stub(
      Mailgun.Client,
      &Req.Test.text(Plug.Conn.put_status(&1, 401), ~s({"Error":"unauthorized"}))
    )

    assert {:error, 401, _body} = MailgunLogger.process_account(account)

    account = reload(account)
    assert account.last_run_status == "error"
    assert account.last_run_error == "401: unauthorized"
    assert account.last_run_event_count == nil
    assert account.last_run_at
  end

  test "process_account returns and saves the error of a 400 response" do
    account = insert(:account)

    Req.Test.stub(
      Mailgun.Client,
      &Req.Test.json(Plug.Conn.put_status(&1, 400), %{"error" => %{"message" => "bad"}})
    )

    assert MailgunLogger.process_account(account) == {:error, "bad"}
    assert %{last_run_status: "error", last_run_error: "bad"} = reload(account)
  end

  test "process_account returns and saves a network error" do
    account = insert(:account)
    Req.Test.stub(Mailgun.Client, &Req.Test.transport_error(&1, :timeout))

    assert {:error, %Req.TransportError{reason: :timeout}} =
             MailgunLogger.process_account(account)

    assert %{last_run_status: "error", last_run_error: "timeout"} = reload(account)
  end

  test "a successful run clears the previous error" do
    account = insert(:account, last_run_status: "error", last_run_error: "401: unauthorized")
    Req.Test.stub(Mailgun.Client, &Req.Test.json(&1, %{"items" => []}))

    MailgunLogger.process_account(account)

    assert %{last_run_status: "ok", last_run_error: nil, last_run_event_count: 0} =
             reload(account)
  end

  describe "store_recent_messages/1" do
    setup do
      store_messages = Application.get_env(:mailgun_logger, :store_messages)
      Application.put_env(:mailgun_logger, :store_messages, true)
      on_exit(fn -> Application.put_env(:mailgun_logger, :store_messages, store_messages) end)
    end

    defp event_with_storage(api_id, hours_ago) do
      timestamp =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(-hours_ago * 3600, :second)
        |> NaiveDateTime.truncate(:second)

      raw = %{"storage" => %{"url" => "https://storage.api.mailgun.net/v3/messages/#{api_id}"}}
      insert(:event, api_id: api_id, timestamp: timestamp, raw: raw, has_stored_message: true)
    end

    test "stores the messages of the recent events on S3 again" do
      test = self()
      recent = event_with_storage("recent", 2)
      event_with_storage("old", 30)
      insert(:event, api_id: "no_storage", timestamp: NaiveDateTime.utc_now())

      Req.Test.stub(Mailgun.Client, fn conn ->
        send(test, {:mailgun, conn.request_path})
        Req.Test.json(conn, %{"body-html" => "<p>Hi</p>"})
      end)

      Req.Test.stub(ExAws, fn conn ->
        send(test, {:s3, conn.method, conn.request_path})
        Plug.Conn.send_resp(conn, 200, "")
      end)

      assert MailgunLogger.store_recent_messages(24) == %{stored: 1, failed: 0}

      assert_received {:mailgun, "/v3/messages/recent"}
      assert_received {:s3, "PUT", "/test-bucket/messages/recent.json"}
      refute_received {:mailgun, _}
      assert Repo.get!(MailgunLogger.Event, recent.id).has_stored_message
    end

    test "counts and flags the messages that Mailgun no longer has" do
      recent = event_with_storage("recent", 2)

      Req.Test.stub(
        Mailgun.Client,
        &Req.Test.json(Plug.Conn.put_status(&1, 404), %{"message" => "not found"})
      )

      assert MailgunLogger.store_recent_messages(24) == %{stored: 0, failed: 1}
      refute Repo.get!(MailgunLogger.Event, recent.id).has_stored_message
    end
  end
end
