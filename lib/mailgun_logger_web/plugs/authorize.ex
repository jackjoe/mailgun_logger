# Controller plug authorization! Just like auth or setup!
# fail-safe if add new action but forget to declare its permissions -> user denied!
defmodule MailgunLoggerWeb.Plugs.Authorize do
  # The plug is used for every request and that is why we can use it to check permissions
  # -> struct %Plug.Conn{} carry the request
  import Plug.Conn
  import Phoenix.Controller

  alias MailgunLogger.Roles
  alias MailgunLoggerWeb.Router.Helpers, as: Routes

  # Initialize the plug with the given options
  def init(opts), do: opts

  # is the plug itself and runs at Request time
  def call(conn, _opts) do
    # What the action is being called in phoenix controller module
    action = action_name(conn)

    # What controller is being called at request time
    controller = controller_module(conn)

    # Get the permission of the controller by reading and module attribute at runtime
    permissions =
      if function_exported?(controller, :action_permissions, 0) do
        controller.action_permissions()
      else
        %{}
      end

    # look for the required permission for the action
    required = Map.get(permissions || %{}, action)

    # Get the current user role
    user = conn.assigns[:current_user]

    cond do
      # fail safe if no permission declared -> Deny
      is_nil(required) ->
        deny(conn)

      # No user
      is_nil(user) ->
        deny(conn)

      # Check permissions at compile time
      Roles.can?(user, required) ->
        conn

      # Deny if permission not found
      true ->
        deny(conn)
    end
  end

  # Helper to deny the request
  defp deny(conn) do
    conn
    |> put_flash(:error, "you dont have permission to access this resource or page")
    |> redirect(to: Routes.event_path(conn, :index))
    |> halt()
  end
end
