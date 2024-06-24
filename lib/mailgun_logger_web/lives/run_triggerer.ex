defmodule MailgunLogger.RunTriggererLive do
  use MailgunLoggerWeb, :live_view

  def mount(_, _, socket) do
    {:ok, assign(socket, :triggered?, false)}
  end

  def render(%{triggered?: true} = assigns) do
    ~H"""
    <div style="background-color: #05ffb0;">New events will be coming in soon!</div>
    """
  end

  def render(assigns) do
    ~H"""
    <button phx-click="trigger_run">trigger new run</button>
    """
  end

  # def handle_event("trigger_run", _, socket) do
  #   Task.start(&MailgunLogger.run/0)
  #   Process.send_after(self(), :reset, 3000)
  #   {:noreply, assign(socket, :triggered?, true)}
  # end

  def handle_info(:reset, socket) do
    {:noreply, assign(socket, :triggered?, false)}
  end
end
