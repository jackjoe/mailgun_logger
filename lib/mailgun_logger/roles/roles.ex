defmodule MailgunLogger.Roles do
  import Ecto.Query, warn: false

  alias MailgunLogger.Role
  alias MailgunLogger.User
  alias MailgunLogger.Repo

  @superuser_role "superuser"
  @admin_role "admin"

  #########################################################

  @default_actions ~w()

  @admin_actions ~w(do_stuff) ++ @default_actions

  @superuser_actions ~w() ++ @admin_actions

  #########################################################

  @doc false
  @spec list_roles() :: [Role.t()]
  def list_roles() do
    Repo.all(Role)
    # We moeten deze pipen zodat er reeds over geloopt wordt. anders krijgen we een array-object terug
    |> Enum.map(&{&1.name, &1.id})
  end



  def get_roles_by_id(ids) do
    Role
    |> where([c], c.id in ^ids)
    |> Repo.all()
  end

  # Via deze functie verkrijgen we een specifieke rol op basis van de id
  def get_role_by_id(id) do
    Role
    |> where([c], c.id in ^[id])
    |> Repo.one()
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

  for action <- @admin_actions do
    action = String.to_atom(action)
    def can?(@admin_role, unquote(action)), do: true
  end

  for action <- @superuser_actions do
    action = String.to_atom(action)
    def can?(@superuser_role, unquote(action)), do: true
  end

  def can?(_, _), do: false

  def is?(%User{roles: roles}, :superuser), do: is(roles, "superuser")
  def is?(%User{roles: roles}, :admin), do: is(roles, "admin")
  def is?(_, _), do: raise("Roles.is/2 requires roles to be preloaded")

  defp is(roles, role) when is_binary(role), do: Enum.map(roles, & &1.name) |> Enum.member?(role)

  def abilities(%User{roles: []}), do: []
  def abilities(%User{roles: roles}), do: hd(roles) |> abilities()
  def abilities(%Role{name: "admin"}), do: @admin_actions
  def abilities(%Role{name: "superuser"}), do: @superuser_actions

  def roles(%User{roles: roles}), do: Enum.map(roles, & &1.name)
end
