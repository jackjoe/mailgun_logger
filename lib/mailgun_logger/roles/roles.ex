defmodule MailgunLogger.Roles do
  import Ecto.Query, warn: false

  alias MailgunLogger.Account
  alias MailgunLogger.Event
  alias MailgunLogger.Role
  alias MailgunLogger.User
  alias MailgunLogger.Repo

  @superuser_role "superuser"
  @admin_role "admin"
  @member_role "member"

  # Forbid roles to be edited/assigned in the app
  @forbidden_roles ~w(superuser)

  #########################################################

  @default_actions ~w()a

  @member_actions ~w()a ++ @default_actions

  @admin_actions ~w(trigger_run view_stats view_graphs)a ++ @member_actions

  @superuser_actions ~w()a ++ @admin_actions

  #########################################################

  @doc false
  @spec list_roles() :: [Role.t()]
  def list_roles() do
    Repo.all(Role)
  end

  def get_roles_by_id(ids) do
    Role
    |> where([c], c.id in ^ids)
    |> Repo.all()
  end

  def get_role_by_name(name) do
    Role
    |> where([c], c.name == ^name)
    |> Repo.one()
  end

  # TODO: I think this returns a user struct and not an array of roles
  @spec get_by_user(User.t()) :: [Role.t()]
  def get_by_user(%User{} = user) do
    user
    |> Repo.preload(:roles)
  end

  @doc """
  Note: User structs passed in here are excepted to have
  roles preloaded!

  Use this when an action does not involve a resource. If it involves a
  resource, use can?/3
  """
  @spec can?(User.t(), atom()) :: boolean()
  def can?(%User{roles: roles}, action), do: can?(roles, action)
  # def can?(%User{} = _user, _action), do: raise("Roles.can?/2 requires roles to be preloaded")

  @spec can?([Role.t()], atom()) :: boolean()
  def can?(roles, action) when is_list(roles) do
    Enum.any?(roles, &can?(&1.name, action))
  end

  # TODO: remove commented alternative example
  # # Allow any action for superusers
  # def can?(%Role{name: "superuser"}, _), do: true

  # def can?(%Role{name: "admin"}, :trigger_run), do: true
  # def can?(%Role{name: "admin"}, :view_stats), do: true
  # def can?(%Role{name: "admin"}, :view_graphs), do: true

  for action <- @member_actions do
    def can?(@member_role, unquote(action)), do: true
  end

  for action <- @admin_actions do
    def can?(@admin_role, unquote(action)), do: true
  end

  for action <- @superuser_actions do
    def can?(@superuser_role, unquote(action)), do: true
  end

  def can?(_, _), do: false

  @doc """
    Check if any of a user's roles have permission to do the action on resource.

    Use this when an action involves a resource. If the action does not involve a
    resource, use can?/2

    It is only necessary to define allow rules. Any unmatched
    check will return false.
  """
  @spec can?(User.t(), atom(), module()) :: boolean()
  def can?(%User{roles: roles}, action, resource),
    do: Enum.any?(roles, fn role -> MailgunLogger.Roles.can?(role, action, resource) end)

  # Allow all actions on all resources for superusers
  def can?(%Role{name: "superuser"}, _, _), do: true

  def can?(%Role{name: "member"}, action, Event)
      when action in [:index, :show],
      do: true

  def can?(%Role{name: "admin"}, action, Event)
      when action in [:index, :show, :stored_message],
      do: true

  def can?(%Role{name: "admin"}, action, Account)
      when action in [:index, :new, :create, :edit, :update, :delete],
      do: true

  def can?(%Role{name: "admin"}, action, User)
      when action in [:index, :new, :create, :edit, :update, :delete],
      do: true

  # Deny fallback
  def can?(_, _, _), do: false

  def is?(%User{roles: roles}, :superuser), do: is(roles, "superuser")
  def is?(%User{roles: roles}, :admin), do: is(roles, "admin")
  def is?(%User{roles: roles}, :member), do: is(roles, "member")
  def is?(_, _), do: raise("Roles.is/2 requires roles to be preloaded")

  defp is(roles, role) when is_binary(role), do: Enum.map(roles, & &1.name) |> Enum.member?(role)

  def abilities(%User{roles: []}), do: []
  def abilities(%User{roles: roles}), do: hd(roles) |> abilities()
  def abilities(%Role{name: "admin"}), do: @admin_actions
  def abilities(%Role{name: "superuser"}), do: @superuser_actions
  def abilities(%Role{name: "member"}), do: @member_actions

  def roles(%User{roles: roles}), do: Enum.map(roles, & &1.name)

  # Used to display role checkboxes on user forms. We do not want forbidden roles
  # to be assignable. These are also filtered on POST requests for security.
  @spec get_assignable_role_names() :: [binary()]
  def get_assignable_role_names() do
    Enum.map(list_roles(), fn role -> role.name end)
    |> filter_forbidden_role_names()
  end

  @spec filter_forbidden_role_names([binary()]) :: [binary()]
  def filter_forbidden_role_names(roles) do
    Enum.filter(roles, fn role_name -> role_name not in @forbidden_roles end)
  end

  # add roles from the form the the user params object so they can be cast
  # in the changeset.
  @spec add_form_roles_to_user_params(map()) :: map()
  def add_form_roles_to_user_params(%{"user" => user_params} = params) do
    # set user_role_names to empty map if it is nil (no checkboxes checked)
    user_role_names_map =
      if params["user_role_names"] == nil, do: %{}, else: params["user_role_names"]

    # params["user_role_names"] will be of shape %{"member" => "member"}
    # so we need to grab just the keys so we have shape ["member"].
    user_role_names =
      Map.keys(user_role_names_map)
      # Filter any forbidden roles for security
      |> filter_forbidden_role_names()

    # Manually adding roles to user_params before changeset is created in
    # Users.update_user/2
    user_params =
      Map.put(
        user_params,
        "roles",
        Enum.map(user_role_names, fn role_name -> get_role_by_name(role_name) end)
      )

    user_params
  end
end
