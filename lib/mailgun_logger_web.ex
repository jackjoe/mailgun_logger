defmodule MailgunLoggerWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use MailgunLoggerWeb, :controller
      use MailgunLoggerWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths(), do: ~w(assets css fonts images js favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller, namespace: MailgunLoggerWeb
      import Plug.Conn
      import MailgunLoggerWeb.Gettext
      alias MailgunLoggerWeb.Router.Helpers, as: Routes

      unquote(verified_routes())
    end
  end

  def view do
    quote do
      use Phoenix.Component

      use Phoenix.View,
        root: "lib/mailgun_logger_web/templates",
        namespace: MailgunLoggerWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [view_module: 1]

      # TODO to be deleted and replaced with components
      def render_partial(template, assigns \\ []) do
        render(MailgunLoggerWeb.PartialView, template, assigns)
      end

      unquote(html_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import MailgunLoggerWeb.Gettext
    end
  end

  defp html_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers
      use Phoenix.LiveView

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import MailgunLoggerWeb.Gettext
      import MailgunLoggerWeb.ErrorHelpers
      import MailgunLoggerWeb.Gettext
      import MailgunLoggerWeb.PagingHelpers
      import MailgunLoggerWeb.ViewHelpers
      alias MailgunLoggerWeb.Router.Helpers, as: Routes

      # Routes generation with the ~p sigil
      unquote(verified_routes())

      import MailgunLoggerWeb.CoreComponents
      import MailgunLoggerWeb.Components.Flop

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def component do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.Component

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent
      unquote(html_helpers())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: MailgunLoggerWeb.Endpoint,
        router: MailgunLoggerWeb.Router,
        statics: MailgunLoggerWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
