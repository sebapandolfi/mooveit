module Validations
    COMMANDS = { 
        "set"  => :set,
        "add"  => :add,
        "replace"  => :replace,
        "append"  => :append,
        "prepend"  => :prepend,
        "cas"  => :cas,
        "get"  => :get_gets,
        "gets"  => :get_gets
      }

    def self.validate_format(meta_data)
        if is_option_incorrect(meta_data[0])
           return "ERROR"
        end
        if is_writing_message(meta_data[0])
           if ( meta_data.length < 5 || meta_data.length > 7)
              return "CLIENT_ERROR, Incorrect number of parameters"
           end
           flag = meta_data[2]
           exp_time = meta_data[3]
           bytes = meta_data[4]
           Integer(flag)
           Integer(exp_time)
           Integer(bytes)
        end
        return false
        rescue
           return "CLIENT_ERROR, Flag, expiration time and bytes must be a Integer"
     end

    def self.is_writing_message(option)
        COMMANDS[option] != :get_gets
    end

     private
    def self.is_option_incorrect(option)
        COMMANDS[option] == nil
    end
end
