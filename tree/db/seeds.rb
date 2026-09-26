# Creates or updates the single admin user. Credentials never live in the code
# or in a file; ./setup passes them in for one run:
#
#   ADMIN_EMAIL=you@example.com ADMIN_PASSWORD=... bin/rails db:seed
#
# ADMIN_PASSWORD can be left out to change only the email of an existing user.
# There is always exactly one user.
email = ENV["ADMIN_EMAIL"].presence
password = ENV["ADMIN_PASSWORD"].presence

if email.nil?
  puts "Skipping admin user: set ADMIN_EMAIL and ADMIN_PASSWORD."
elsif password.nil? && User.none?
  puts "Skipping admin user: ADMIN_PASSWORD is required to create it."
else
  User.transaction do
    user = User.first_or_initialize
    user.email_address = email
    user.password = password if password
    user.save!
    User.where.not(id: user.id).destroy_all
  end
  puts "Admin user: #{User.sole.email_address}"
end
