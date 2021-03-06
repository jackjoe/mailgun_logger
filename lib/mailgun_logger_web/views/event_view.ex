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

  def event_name(event_name) when event_name in ~w(delivered) do
    ~E"""
    <span style="background-color: lime; padding: 3px 5px; color: green;"><%= event_name %></span>
    """
  end

  def event_name(event_name), do: event_name

  def event_type(event_type) when event_type in ~w(warn) do
    ~E"""
    <span style="background-color: orange; padding: 3px 5px; color: #fff;"><%= event_type %></span>
    """
  end

  def event_type(event_type) when event_type in ~w(failed error) do
    ~E"""
    <span style="background-color: red; padding: 3px 5px; color: #fff;"><%= event_type %></span>
    """
  end

  def event_type(event_type), do: event_type
end
