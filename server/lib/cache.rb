class Cache
   def initialize()
      @counter_cas = 0
      @cache = Hash.new 
   end

   def store_data(meta_data,message)
      key,flag,exp_time,bytes = parse_data(meta_data)
      if(exp_time >= 0)
         @cache[key] = [flag,Time.now,exp_time,bytes,get_cas,message]
      end
   end

   def append_data(meta_data,message)
      key,flag,exp_time,bytes = parse_data(meta_data)
      @cache[key][3] = @cache[key][3] + bytes
      @cache[key][4] = get_cas
      @cache[key][5] = @cache[key][5] ++ message
   end

   def prepend_data(meta_data,message)
      key,flag,exp_time,bytes = parse_data(meta_data)
      @cache[key][3] = @cache[key][3] + bytes
      @cache[key][4] = get_cas
      @cache[key][5] = message ++ @cache[key][5]
   end

   def parse_data(meta_data)
      [meta_data[1],meta_data[2], Integer(meta_data[3]), Integer(meta_data[4])]
   end 

   def get_cas
      @counter_cas += 1
   end
   
   def exist_key(key)
      get(key) != nil
   end

   def get(key)
      return check_exp_time(key)
   end

   def check_exp_time(key)
      data = @cache[key]
      if data != nil
         old_time = data[1]
         exp_time = data[2]
         if exp_time < 60*60*24*30 
            if ((Time.now - old_time) - exp_time) <= 0
               return data
            end
         else
            if Time.now.to_i < exp_time 
               return data
            end
         end
         @cache.delete(key)
      end
      return nil
   end

end
