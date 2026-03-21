defmodule MailgunLogger.Users do
  import Ecto.Query, warn: false

  alias MailgunLogger.Repo
  alias MailgunLogger.User


  @type ecto_user() :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  @type maybe_user() :: User.t() | nil

  @spec list_users() :: [User.t()]
  def list_users() do
    Repo.all(User) |> Repo.preload(:roles)
  end

  @spec get_user!(integer | String.t()) :: User.t()
  def get_user!(id) do
    from(
      u in User,
      where: u.id == ^id,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one!()
  end

  @spec get_user(integer | String.t()) :: maybe_user()
  def get_user(id) do
    from(
      u in User,
      where: u.id == ^id,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one()
  end

  @spec get_user_by_token!(String.t()) :: User.t()
  def get_user_by_token!(token) do
    from(
      u in User,
      where: u.token == ^token,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one!()
  end

  @spec get_user_by_token(String.t()) :: maybe_user()
  def get_user_by_token(token) do
    from(
      u in User,
      where: u.token == ^token,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one()
  end

  @spec authenticate(String.t(), String.t()) ::
          {:error, :unknown_user} | {:error, any()} | {:ok, User.t()}
  def authenticate(email, password) do
    from(
      u in User,
      where: u.email == ^email,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one()
    |> case do
      nil ->
        {:error, :unknown_user}

      user ->
        case Argon2.verify_pass(password, user.encrypted_password) do
          true -> {:ok, user}
          false -> {:error, "invalid password"}
        end
    end
  end

  @spec get_user_by_email(String.t()) :: maybe_user()
  def get_user_by_email(email) do
    from(
      u in User,
      where: u.email == ^email
    )
    |> Repo.one()
  end

  @spec get_user_by_reset_token(String.t()) :: maybe_user()
  def get_user_by_reset_token(reset_token) do
    from(
      u in User,
      where: u.reset_token == ^reset_token,
      left_join: roles in assoc(u, :roles),
      preload: [roles: roles]
    )
    |> Repo.one()
  end

  @spec gen_password_reset_token(String.t()) :: ecto_user()
  def gen_password_reset_token(email) do
    from(
      u in User,
      where: u.email == ^email
    )
    |> Repo.one()
    |> case do
      nil ->
        {:error, :unknown_user}

      user ->
        token = gen_token(46)

        user
        |> User.password_forgot_changeset(%{reset_token: token})
        |> Repo.update()
    end
  end

  defp gen_token(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  @spec reset_password(User.t(), map()) :: ecto_user()
  def reset_password(%User{} = user, attrs \\ %{}) do
    user
    |> User.password_reset_changeset(attrs)
    |> Ecto.Changeset.change(reset_token: nil)
    |> Repo.update()
  end

  @spec any_users?() :: boolean()
  def any_users?(), do: Repo.exists?(from(u in User, select: u.id))

  @spec create_admin(map()) :: ecto_user()
  def create_admin(attrs) do
    %User{}
    |> User.admin_changeset(attrs)
    |> Repo.insert()
  end

  @spec create_user(map) :: ecto_user()
  def create_user(params) do
    %User{}
    |> User.changeset(params)
    |> Repo.insert()
  end

  @spec update_user(User.t(), map) :: ecto_user()
  def update_user(user, params) do
    user
    |> User.update_changeset(params)
    |> Repo.update()
  end

  @spec delete_user(User.t()) :: ecto_user()
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @spec create_managed_user(map) :: ecto_user()
  def create_managed_user(params) do
    %User{}
    |> User.management_create_changeset(params)
    |> Repo.insert()
  end

  @spec update_managed_user(User.t(), User.t(), map()) :: ecto_user()
  def update_managed_user(current_user, user_to_update, params) do
    if self_downgrade?(current_user, user_to_update, params) do
      {:error, self_downgrade_changeset(user_to_update, params)}
    else
      user_to_update
      |> Repo.preload(:roles)
      |> User.management_update_changeset(params)
      |> Repo.update()
    end
  end

  # true als je jezelf aan het downgraden bent, je een managing user (admin of superuser) bent en je de management rol niet behoudt in de update params
  defp self_downgrade?(current_user, user_to_update, params) do
    current_user.id == user_to_update.id and
      managing_user?(current_user) and
      not keeps_management_role?(params)
  end

  defp managing_user?(user) do
    MailgunLogger.Roles.is?(user, :admin) or
      MailgunLogger.Roles.is?(user, :superuser)
  end

  defp keeps_management_role?(params) do
    role_ids =
      params["role_ids"]
      |> Kernel.||([])
      |> Enum.reject(&(&1 in ["", nil]))

    roles = MailgunLogger.Roles.get_roles_by_id(role_ids)
    role_names = Enum.map(roles, & &1.name)

    "admin" in role_names or "superuser" in role_names
  end

  defp self_downgrade_changeset(user, params) do
    user
    |> User.management_update_changeset(params)
    |> Ecto.Changeset.add_error(:roles, "You cannot downgrade your own admin privileges")
  end
end
