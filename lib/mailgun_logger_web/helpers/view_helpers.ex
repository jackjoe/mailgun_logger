defmodule MailgunLoggerWeb.ViewHelpers do
  alias Phoenix.Controller

  def active_link?(conn, controllers) when is_list(controllers),
    do: Enum.member?(controllers, Controller.controller_module(conn))

  def active_link?(conn, controller), do: active_link?(conn, [controller])

  def active_link?(conn, controller, action) do
    member? = active_link?(conn, controller)
    action_name = Controller.action_name(conn)
    member? and action_name == action
  end

  def active_link_class(conn, controllers) do
    if active_link?(conn, controllers), do: "is-active", else: ""
  end

  def active_link_class(conn, controller, action) do
    member? = active_link?(conn, controller)
    action_name = Controller.action_name(conn)

    if member? and action_name == action do
      "is-active"
    else
      ""
    end
  end
end
