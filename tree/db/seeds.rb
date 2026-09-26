# Creates or updates the single admin user from the environment. Credentials
# never live in the code:
#
#   ADMIN_EMAIL=you@example.com ADMIN_PASSWORD=... bin/rails db:seed
#
# Runs automatically when the database is first created (bin/rails db:prepare).
# Re-run it to change the email or password; it always keeps exactly one user.
email = ENV["ADMIN_EMAIL"]
password = ENV["ADMIN_PASSWORD"]

if email.present? && password.present?
  User.transaction do
    user = User.first_or_initialize
    user.update!(email_address: email, password: password)
    User.where.not(id: user.id).destroy_all
  end
  puts "Admin user: #{User.sole.email_address}"
else
  puts "Skipping admin user: set ADMIN_EMAIL and ADMIN_PASSWORD."
end
