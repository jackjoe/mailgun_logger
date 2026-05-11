defmodule MailgunLogger.Roles do
  import Ecto.Query, warn: false

  alias MailgunLogger.Role
  alias MailgunLogger.User
  alias MailgunLogger.Repo

  @superuser_role "superuser"
  @admin_role "admin"

  # Create an new role
  @member_role "member"

  # Task 1:
  # Permissions for member is looking at the events + details on \events pages && Profile changes on /Profile
  # (Not: stats, Accounts, Users) interface & router off limits
  #
  # Update seeds to add the member role in database to use in the application []

  # Task 2:
  # Admin and superuser roles need to have the permissions to edit user & create user
  # can add 1 or multiple roles to a user
  # An user except from the superuser (owner or first to login) cannot downgrade himself!
  # Write an unit test (Phoenix/ExUnit) for these task and permissions
  #

  #########################################################

  @default_actions ~w(view_profile)

  @member_actions ~w(view_event view_stats view_graphs) ++ @default_actions

  @admin_actions ~w(trigger_run view_users edit_user create_user delete_user) ++ @member_actions

  @superuser_actions ~w() ++ @admin_actions

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

  @spec get_by_user(User.t()) :: [Role.t()]
  def get_by_user(%User{} = user) do
    user
    |> Repo.preload(:roles)
  end

  @doc """
  Note: User structs passed in here are excepted to have
  roles preloaded!
  """
  @spec can?(User.t(), atom()) :: boolean()
  def can?(%User{roles: roles}, action), do: can?(roles, action)
  # def can?(%User{} = _user, _action), do: raise("Roles.can?/2 requires roles to be preloaded")

  @spec can?([Role.t()], atom()) :: boolean()
  def can?(roles, action) when is_list(roles) do
    Enum.any?(roles, &can?(&1.name, action))
  end

  # Actions

  # Add compile time permission
  for action <- @member_actions do
    action = String.to_atom(action)
    def can?(@member_role, unquote(action)), do: true
  end

  for action <- @admin_actions do
    action = String.to_atom(action)
    def can?(@admin_role, unquote(action)), do: true
  end

  for action <- @superuser_actions do
    action = String.to_atom(action)
    def can?(@superuser_role, unquote(action)), do: true
  end

  def can?(_, _), do: false

  # Include member in the helper functions
  def is?(%User{roles: roles}, :superuser), do: is(roles, "superuser")
  def is?(%User{roles: roles}, :admin), do: is(roles, "admin")
  def is?(%User{roles: roles}, :member), do: is(roles, "member")
  def is?(_, _), do: raise("Roles.is/2 requires roles to be preloaded")

  defp is(roles, role) when is_binary(role), do: Enum.map(roles, & &1.name) |> Enum.member?(role)

  def abilities(%User{roles: []}), do: []
  def abilities(%User{roles: roles}), do: hd(roles) |> abilities()

  def abilities(%Role{name: "member"}), do: @member_actions
  def abilities(%Role{name: "admin"}), do: @admin_actions
  def abilities(%Role{name: "superuser"}), do: @superuser_actions

  def roles(%User{roles: roles}), do: Enum.map(roles, & &1.name)
end
