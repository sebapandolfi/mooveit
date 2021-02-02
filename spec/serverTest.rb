require 'socket'

class Server

   #Initialization
   COMMANDS = {
      "set"  => :set,
      "add"  => :add_replace,
      "replace"  => :add_replace,
      "append"  => :append_prepend,
      "prepend"  => :append_prepend,
      "cas"  => :cas,
      "get"  => :get_gets,
      "gets"  => :get_gets
    }
    @@threads = []
    @@connected_clients = Hash.new

   def initialize(socket_port , socket_address)
      @users = Hash.new 
      @mutex_users = Mutex.new
      @server_socket = TCPServer.open(socket_address, socket_port)
      @counter_cas = 0
      @mutex_cas = Mutex.new
      @cache = Hash.new 
      @mutex_cache = Mutex.new
      puts 'Started server.........'
      run
   end

   #handle critical problem in server
   def self.shut_down
      puts "\nShutting down gracefully..."
      @@threads.each { |thr| thr.exit }
      @@connected_clients.each do |conn, value|
         conn.puts "SERVER_ERROR, closing connection"
         conn.close
      end
   end

    # Trap ^C 
   Signal.trap("INT") do
      shut_down
      exit
   end
    
    # Trap `Kill `
   Signal.trap("TERM") do
      shut_down
      exit
   end

   #handle new client connection
   def run
      loop{
         client_connection = @server_socket.accept
         @@threads << Thread.start(client_connection) do |conn| # open thread for each accepted connection
            @@connected_clients[conn] = conn
            authenticate(conn)
         end
      }.join
   end

   #authentication of new connection
   def authenticate(conn)
      first_msg = conn.gets.chomp.split(" ")
      if (first_msg[0] == "set") # first message is always authentication
         user_pass = conn.gets.chomp.split(" ")
         if(user_pass.length == 2) # doesnt accept empty password or more than 2 parameters
            user_name = user_pass[0]
            password = user_pass[1]
            flag_auth = false
            @mutex_users.synchronize {
               if (@users[user_name] == nil || @users[user_name] == password ) # if user doesnt exist, its created
                  @users[user_name] = password
                  flag_auth = true
               end
            }
         else
            conn.puts "CLIENT_ERROR, username and password cant be empty"
            authenticate(conn)
         end
      else
         conn.puts "CLIENT_ERROR, Please authenticate first with a set message"
         authenticate(conn)
      end
      if flag_auth
         conn.puts "STORED"
         establish_option(conn) # allow chatting
      else
         conn.puts "CLIENT_ERROR, username and password doesnt match"
         authenticate(conn)
      end
   end

   #waits for new request of client
   def establish_option(conn)
         meta_data = conn.gets.chomp.split(" ")
         option = meta_data[0]
         if (COMMANDS[option] == nil)
            conn.puts "ERROR"
            establish_option(conn)
         else
            send(COMMANDS[option],meta_data,conn,option)
         end
   end

   #client commands functions
   def set(meta_data,conn,option)
      if(validate_storage(meta_data,conn))
         message = read_message(meta_data,conn)
         clean_socket(conn)      
         @mutex_cache.synchronize {
            store_data(meta_data,message)
         }
         if meta_data.length == 5
            conn.puts "STORED"
         end
      end
      establish_option(conn)
   end

   def add_replace(meta_data,conn,option)
      if(validate_storage(meta_data,conn))
         message = read_message(meta_data,conn)
         clean_socket(conn)    
         exist_key = false
         key = meta_data[1]
         @mutex_cache.synchronize {
            if(@cache[key] != nil) 
               exist_key = true
            end
            if option == "add" && !exist_key
               store_data(meta_data,message)
            elsif option == "replace" && exist_key
               store_data(meta_data,message)
            end
         }
         if option == "add" && !exist_key && meta_data.length == 5
            conn.puts "STORED"
         elsif option == "replace" && exist_key && meta_data.length == 5
            conn.puts "STORED"
         elsif meta_data.length == 5
            conn.puts "NOT_STORED"
         end
      end
      establish_option(conn)
   end

   def append_prepend(meta_data,conn,option)
      if(validate_storage(meta_data,conn))
         message = read_message(meta_data,conn)
         clean_socket(conn)    
         exist_key = false
         key = meta_data[1]
         @mutex_cache.synchronize {
         if(@cache[key] != nil) 
            exist_key = true
            @cache[key][4] = get_cas
            if (option == "append")
               @cache[key][5] = @cache[key][5] ++ message
            else
               @cache[key][5] = message ++ @cache[key][5]
            end
            @cache[key][3] += Integer(meta_data[4]) 
         end
         }
         if exist_key && meta_data.length == 5
            conn.puts "STORED"
         elsif meta_data.length == 5
            conn.puts "NOT_STORED"
         end
      end
      establish_option(conn)
   end

   def cas(meta_data,conn,option)
      if(validate_storage(meta_data,conn))
         message = read_message(meta_data,conn)
         clean_socket(conn)    
         exist_key = false
         key = meta_data[1]
         old_data = nil
         cas_value = Integer(meta_data[5])
         @mutex_cache.synchronize {
            old_data = @cache[key]
            if(old_data != nil && @cache[key][4] == cas_value) 
               exist_key = true
               store_data(meta_data,message)
            end
         }
         if meta_data.length == 6
            if exist_key 
               conn.puts "STORED"
            elsif old_data == nil
               conn.puts "NOT_FOUND"
            elsif
               conn.puts "EXISTS"
            end
         end
      end
      establish_option(conn)
   end

   def get_gets(meta_data,conn,option)
      head , *keys = meta_data; # in head its the command
      keys.each do |key|
         exist_key = nil
         @mutex_cache.synchronize{
            exist_key = @cache[key]
         }
         if (exist_key != nil)
            flag_exp_time = check_exp_time(exist_key[1],exist_key[2],key)
            if flag_exp_time && option == "get"
               conn.puts "VALUE #{key} #{exist_key[0]} #{exist_key[3]}"
               conn.puts exist_key[5]
            elsif flag_exp_time
               conn.puts "VALUE #{key} #{exist_key[0]} #{exist_key[3]} #{exist_key[4]}"
               conn.puts exist_key[5]
            end
         end
      end
      conn.puts "END"
      establish_option(conn)
   end

   #auxiliar functions
   def check_exp_time(old_time,exp_time,key)
      flag_exp_time = false
      if exp_time < 60*60*24*30 
         if ((Time.now - old_time) - exp_time) <= 0
            flag_exp_time = true 
         end
      else
         if Time.now.to_i < exp_time 
            flag_exp_time = true
         end
      end
      if flag_exp_time
         return flag_exp_time #return true if expiration time is valid
      else
         @mutex_cache.synchronize{
            @cache.delete(key)
         }
         return flag_exp_time
      end
   end

   def validate_storage(meta_data,conn)
      if ( meta_data.length < 5 || meta_data.length > 7)
         conn.puts "CLIENT_ERROR, Incorrect number of parameters"
         return false
      end
      flag = meta_data[2]
      exp_time = meta_data[3]
      bytes = meta_data[4]
      Integer(flag)
      Integer(exp_time)
      Integer(bytes)
      return true
      rescue
         conn.puts "CLIENT_ERROR, Flag, expiration time and bytes must be a Integer"
         return false 
   end

   def get_cas
      @mutex_cas.synchronize {
         @counter_cas += 1
         return @counter_cas
      }
   end

   def store_data(meta_data,message)
      key = meta_data[1]
      flag = meta_data[2]
      exp_time = Integer(meta_data[3])
      bytes = Integer(meta_data[4])
      if(exp_time >= 0)
         @cache[key] = [flag,Time.now,exp_time,bytes,get_cas,message]
      end
   end

   def clean_socket(conn)
      data_hanging = IO.select([conn],nil,nil, 0)
      if data_hanging
         clean_data = conn.gets
      end
   end

   def read_message(meta_data,conn)
      bytes = Integer(meta_data[4])
      if bytes > 0
         return conn.read(bytes)
      else
         return nil
      end
   end
   
end
