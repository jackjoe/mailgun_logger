defmodule MailgunLoggerWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use MailgunLoggerWeb, :html

  alias MailgunLoggerWeb.AccountController
  alias MailgunLoggerWeb.EventController
  alias MailgunLoggerWeb.PageController
  alias MailgunLoggerWeb.UserController

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates("layouts/*")

  @doc """
  Renders your app layout: the navigation, the flash messages,
  the page content and the footer.

  ## Examples

      <Layouts.app flash={@flash} conn={@conn}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:conn, Plug.Conn, required: true, doc: "the conn, to find the user and the active page")

  slot(:inner_block, required: true)

  def app(assigns) do
    assigns = assign(assigns, :current_user, assigns.conn.assigns[:current_user])

    ~H"""
    <header id="app-header">
      <div class="top">
        <nav id="main-nav">
          <div id="app-logo">
            <a href={~p"/events"}>
              <span class="logo-mark">&gt;_</span><span class="logo-text">ML</span>
            </a>
          </div>
          <ul>
            <%= if @current_user do %>
              <li>
                <.link href={~p"/events"} class={active_class(@conn, EventController)}>Events</.link>
              </li>
              <li>
                <.link href={~p"/stats"} class={active_class(@conn, PageController, :stats)}>
                  Stats
                </.link>
              </li>
              <li>
                <.link href={~p"/accounts"} class={active_class(@conn, AccountController)}>
                  Accounts
                </.link>
              </li>
              <li>
                <.link href={~p"/users"} class={active_class(@conn, UserController)}>Users</.link>
              </li>
              <li class="nav-right">
                <details class="nav-dropdown">
                  <summary class="nav-dropdown-toggle">
                    <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
                      <path
                        fill-rule="evenodd"
                        d="M7.429 1.525a3.5 3.5 0 011.142 0 .75.75 0 01.57.549l.246 1.058a1.08 1.08 0 001.466.625l.97-.478a.75.75 0 01.758.069 5.5 5.5 0 01.572.572.75.75 0 01.069.758l-.478.97a1.08 1.08 0 00.625 1.466l1.058.246a.75.75 0 01.549.57 3.5 3.5 0 010 1.142.75.75 0 01-.549.57l-1.058.246a1.08 1.08 0 00-.625 1.466l.478.97a.75.75 0 01-.069.758 5.5 5.5 0 01-.572.572.75.75 0 01-.758.069l-.97-.478a1.08 1.08 0 00-1.466.625l-.246 1.058a.75.75 0 01-.57.549 3.5 3.5 0 01-1.142 0 .75.75 0 01-.57-.549l-.246-1.058a1.08 1.08 0 00-1.466-.625l-.97.478a.75.75 0 01-.758-.069 5.5 5.5 0 01-.572-.572.75.75 0 01-.069-.758l.478-.97a1.08 1.08 0 00-.625-1.466l-1.058-.246a.75.75 0 01-.549-.57 3.5 3.5 0 010-1.142.75.75 0 01.549-.57l1.058-.246a1.08 1.08 0 00.625-1.466l-.478-.97a.75.75 0 01.069-.758 5.5 5.5 0 01.572-.572.75.75 0 01.758-.069l.97.478a1.08 1.08 0 001.466-.625l.246-1.058a.75.75 0 01.57-.549zM8 11a3 3 0 100-6 3 3 0 000 6z"
                      />
                    </svg>
                  </summary>
                  <div class="nav-dropdown-menu">
                    <div class="nav-dropdown-header">{@current_user.email}</div>
                    <div class="nav-dropdown-divider"></div>
                    <.link href={~p"/profile"} class="nav-dropdown-item">Profile</.link>
                    <.link href={~p"/logout"} class="nav-dropdown-item">Logout</.link>
                  </div>
                </details>
              </li>
            <% else %>
              <li class="nav-right"><.link href={~p"/login"}>Login</.link></li>
            <% end %>
          </ul>
        </nav>
      </div>
    </header>
    <main>
      <.flash_group flash={@flash} />
      {render_slot(@inner_block)}
    </main>
    <footer>
      <.link href={~p"/non-affiliation"}>Mailgun</.link>
      Logger v{Application.spec(:mailgun_logger, :vsn)}
      | created by Jack + Joe |
      <a href="https://raw.githubusercontent.com/jackjoe/mailgun_logger/master/LICENSE">
        MIT License
      </a>
    </footer>
    """
  end

  @doc """
  Returns the theme of the signed in user, or "dark" without a user.
  """
  def theme_preference(assigns) do
    case assigns[:current_user] do
      %{theme: theme} when theme in ~w(dark light system) -> theme
      _ -> "dark"
    end
  end

  defp active_class(conn, controller, action \\ nil) do
    active? =
      Phoenix.Controller.controller_module(conn) == controller and
        (is_nil(action) or Phoenix.Controller.action_name(conn) == action)

    if active?, do: "is-active", else: ""
  end
end
