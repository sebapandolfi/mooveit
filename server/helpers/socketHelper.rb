module SocketHelper
    def self.read_socket(conn,bytes)
        bytes = Integer(bytes)
        response = conn.read(bytes)
        clean_socket(conn) 
        return response
     end
  
     def self.clean_socket(conn)
        data_hanging = IO.select([conn],nil,nil, 0)
        if data_hanging
           clean_data = conn.gets
        end
     end
  
     def self.socket_puts(conn,response)
        if response != nil
           conn.puts response
        end
     end
end
