module Auth

   #authentication
   def self.authenticate(user_pass)
      if validate_data(user_pass) # doesnt accept empty password or more than 2 parameters
         response = is_pass_correct(user_pass)
      else
         response = "CLIENT_ERROR, username and password must be 2 parameters"
       end      
   end

   private
   def self.is_pass_correct(user_pass)
      user_name = user_pass[0]
      password = user_pass[1]
      Dir.chdir(File.dirname(__FILE__))
      File.foreach("../Users/users.txt") { |line| 
         correct_data = line.split(" ")
         if (user_name == correct_data[0]) && (password == correct_data[1])
            return "STORED"
         end
      }
      response = "CLIENT_ERROR, username and password doesnt match"

   end

   def self.validate_data (user_pass)
      user_pass.length == 2
   end
end