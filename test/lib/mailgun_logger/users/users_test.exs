defmodule MailgunLogger.Users.UsersTest do
  use MailgunLogger.DataCase

  alias MailgunLogger.Users

  describe "count_superusers/0" do
    test "returns 0 when there are no superusers" do
      assert Users.count_superusers() == 0
    end

    test "returns the correct count" do
      insert(:superuser)
      insert(:superuser)
      insert(:admin)
      assert Users.count_superusers() == 2
    end
  end

  # Create User
  # Update User
end
