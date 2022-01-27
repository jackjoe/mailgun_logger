defmodule MailgunLoggerWeb.EventView do
  use MailgunLoggerWeb, :view
  @moduledoc false

  def subject(%{message_subject: nil}), do: ""
  def subject(%{message_subject: ""}), do: ""

  def subject(%{message_subject: subject}) do
    case String.length(subject) > 20 do
      true -> "#{subject |> String.slice(0, 20) |> String.trim_trailing()}..."
      false -> subject
    end
  end

  def event_name("delivered") do
    assigns = %{}

    ~L"""
    <span style="background-color: lime; padding: 3px 5px; color: green;">delivered</span>
    """
  end

  def event_name("failed") do
    assigns = %{}

    ~L"""
    <span style="background-color: red; padding: 3px 5px; color: white;">failed</span>
    """
  end

  def event_name(event_name), do: event_name

  def event_type(event_type) when event_type in ~w(warn) do
    assigns = %{event_type: event_type}

    ~L"""
    <span style="background-color: orange; padding: 3px 5px; color: #fff;"><%= event_type %></span>
    """
  end

  def event_type(event_type) when event_type in ~w(failed error) do
    assigns = %{event_type: event_type}

    ~L"""
    <span style="background-color: red; padding: 3px 5px; color: #fff;"><%= event_type %></span>
    """
  end

  def event_type(event_type), do: event_type
end
