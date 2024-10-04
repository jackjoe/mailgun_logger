defmodule MailgunLogger.Repo.Migrations.UserRoleCascadeDelete do
  use Ecto.Migration

  def change do
    alter table(:roles_users) do
      # When we delete a user, we want all roles_users entries for that
      # user to be deleted as well. We will get a foreign key constraint error
      # otherwise.
      # Modify on_delete on existing foreign key. The from: option is used
      # by ecto in case of rollbacks.
      # https://hexdocs.pm/ecto_sql/Ecto.Migration.html#modify/3-examples
      modify(:user_id, references(:users, on_delete: :delete_all),
        from: references(:user_id, on_delete: :nothing)
      )
    end
  end
end
