# This file contains seeds to aid with development

# Create example users

MailgunLogger.Users.create_admin(%{
  email: "admin@example.com",
  # Conform to password requirements
  password: "adminadmin"
})

# This user will have a 'member' role
MailgunLogger.Users.create_user(%{
  firstname: "member_first_name",
  lastname: "member_last_name",
  email: "member@example.com",
  # Conform to password requirements
  password: "membermember"
})
