require_relative 'cache.rb'
require_relative 'authentication.rb'

class ServerController
   include Auth
   #Initialization
   def initialize()
      @cache = Cache.new()
   end

   def handle_request(meta_data,message)
      response = send(meta_data[0],meta_data,message)
      return is_no_reply(meta_data,response)
   end

   def authenticate(user_pass)
      response = Auth.authenticate(user_pass)
   end

   private
   #client commands functions
   def set(meta_data,message)    
      @cache.store_data(meta_data,message)
      return "STORED"
   end

   def add(meta_data,message)
      if @cache.exist_key(meta_data[1]) 
         return "NOT_STORED"
      else
         @cache.store_data(meta_data,message)
         return "STORED"
      end
   end

   def replace(meta_data,message)
      if !@cache.exist_key(meta_data[1]) 
         return "NOT_STORED"
      else
         @cache.store_data(meta_data,message)
         return "STORED"
      end
   end

   def append(meta_data,message)
      if !@cache.exist_key(meta_data[1]) 
         return "NOT_STORED"
      else
         @cache.append_data(meta_data,message)
         return "STORED"
      end
   end

   def prepend(meta_data,message)
      if !@cache.exist_key(meta_data[1]) 
         return "NOT_STORED"
      else
         @cache.prepend_data(meta_data,message)
         return "STORED"
      end
   end

   def cas(meta_data,message)
      cas_value = Integer(meta_data[5])
      old_data = @cache.get(meta_data[1])
      if old_data == nil
         return "NOT_FOUND"
      elsif old_data[4] != cas_value
         return "EXISTS"
      elsif
         @cache.store_data(meta_data,message)
         return "STORED"
      end
   end

   def get(meta_data,message)
      head , *keys = meta_data; # in head its the command
      response = "END"
      keys.reverse.each do |key|
         data = @cache.get(key)
         if (data != nil)
            response = "VALUE #{key} #{data[0]} #{data[3]}\n#{data[5]}\n" ++ response 
         end
      end
      return response
   end

   def gets(meta_data,message)
      head , *keys = meta_data; # in head its the command
      response = "END"
      keys.reverse.each do |key|
         data = @cache.get(key)
         if (data != nil)
            response = "VALUE #{key} #{data[0]} #{data[3]} #{data[4]}\n#{data[5]}\n" ++ response
         end
      end
      return response
   end

   #auxiliar functions

   def is_no_reply(meta_data,response)
      if meta_data[0] != "cas" && meta_data.length == 5
         return response
      end
      if meta_data[0] == "cas" && meta_data.length == 6
         return response
      end
      if meta_data[0] == "get" || meta_data[0] == "gets"
         return response
      end
      return nil
   end
end
