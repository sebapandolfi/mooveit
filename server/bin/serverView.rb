require 'socket'
require_relative '../lib/serverController.rb'
require_relative '../helpers/validation.rb'
require_relative '../helpers/socketHelper.rb'

class ServerView
   include Validations
   include SocketHelper

   #Initialization
   @@threads = []
   @@connected_clients = Hash.new
   @@authenticated_clients = Hash.new

   def initialize(socket_port , socket_address)
      @server_socket = TCPServer.open(socket_address, socket_port)
      @server = ServerController.new() 
      puts 'Started server.........'
      run
   end
   
   private
   #handle new client connection
   def run
      loop{
         client_connection = @server_socket.accept
         @@threads << Thread.start(client_connection) do |conn| # open thread for each accepted connection
            @@connected_clients[conn] = conn
            @@authenticated_clients[conn] = false
            handle_connection(conn)
         end
      }.join
   end

   def handle_connection(conn)
      meta_data = conn.gets.chomp.split(" ")
      is_valid_request = Validations.validate_format(meta_data)
      if !is_valid_request #if false the format is correct
         if is_authenticated(conn)
            if Validations.is_writing_message(meta_data[0]) # metadata[0] is the command name
               message = SocketHelper.read_socket(conn,meta_data[4]) # meta_data[4] is bytes
            end
            SocketHelper.socket_puts(conn,@server.handle_request(meta_data,message))
         else 
            if meta_data[0] == "set"
               user_pass = SocketHelper.read_socket(conn,Integer(meta_data[4]) + 1).split(" ") # meta_data[4] is bytes length
               response = @server.authenticate(user_pass)
               if response == "STORED" # client authenticated successfully
                  @@authenticated_clients[conn]= true
               end
               conn.puts response
            else
               conn.puts "CLIENT_ERROR, Please authenticate first with a set message"
            end   
         end
      else # if true is_valid_request is the error message
         conn.puts is_valid_request
      end
      handle_connection(conn)
   end

   #auxiliar functions

   def is_authenticated(conn)
      @@authenticated_clients[conn]
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
end
