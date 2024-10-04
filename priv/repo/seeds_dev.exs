# This file contains seeds to aid with development

alias MailgunLogger.Users

# Create example users

Users.create_admin(%{
  email: "admin@example.com",
  # Conform to password requirements
  password: "adminadmin"
})

Users.create_user!(%{
  firstname: "member_first_name",
  lastname: "member_last_name",
  email: "member@example.com",
  password: "membermember"
})
|> Users.assign_role("member")
