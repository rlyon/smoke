
def create_user
  u = Smoke::Server::User.new
  puts "Enter the user's full name: "
  u.display_name = gets
  puts "Enter the user's email: "
  u.email = gets
  puts "Enter the username: "
  u.username = gets
  puts "Enter the password: "
  u.password = gets
  u.expires_at = 1.years
  u.access_id = String.random(:length => 20, :charset => :alnum_upper)
  u.secret_key = String.random(:length => 40)
  u.is_active = true
  u.save
  
  puts "ACCOUNT INFORMATION"
  puts "-------------------"
  puts "Display Name:  #{u.display_name}"
  puts "Email:         #{u.email}"
  puts "Username:      #{u.username}"
  puts "Password:      #{u.password}"
  puts "Expires:       #{u.expires_at}" 
  puts "Access ID:     #{u.access_id}"
  puts "Secret Key:    #{u.secret_key}"
end

