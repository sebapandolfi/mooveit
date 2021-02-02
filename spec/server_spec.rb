require "serverTest"

describe Server do
    before :all do
        port = 10044
        @server  = Thread.new {Server.new(port, "0.0.0.0") } 
        @client1 = TCPSocket.open( "localhost", port )
        @client2 = TCPSocket.open( "localhost", port )
    end

    context 'connection of client' do       
        before :all do
            x = Thread.new {
                @client1.puts "set"
                @client1.puts "user pass"
            }
            y = Thread.new {
                @response1 = @client1.gets.chomp
            }
            x.join  
            y.join
            x2 = Thread.new {
                @client2.puts "set"
                @client2.puts "user bad"
                @client2.puts "set"
                @client2.puts "user"
                @client2.puts "user"
                @client2.puts "set"
                @client2.puts "user pass"
            }
            y2 = Thread.new {
                @response2 = @client2.gets.chomp
                @response3 = @client2.gets.chomp
                @response4 = @client2.gets.chomp
                @response5 = @client2.gets.chomp
            }
            x2.join  
            y2.join
        end

        it "authentication success" do
            expect(@response1).to eq("STORED")
        end

        it "authentication user and pass doesnt match" do
            expect(@response2).to eq("CLIENT_ERROR, username and password doesnt match")
        end

        it "authentication empty field" do
            expect(@response3).to eq("CLIENT_ERROR, username and password cant be empty")
        end

        it "authentication first message must be set" do
            expect(@response4).to eq("CLIENT_ERROR, Please authenticate first with a set message")
        end

        it "authentication user and pass match" do
            expect(@response5).to eq("STORED")
        end
    end

    context 'set data' do
        before :all do
            x = Thread.new {
                @client1.puts "set 0 3 1000 3"
                @client1.puts "set"
                @client1.puts "set 5 sa 3 3"
                @client1.puts "set 5 4 sa 3"
                @client1.puts "set 1 4 1000 4 nr"
                @client1.puts "test"
                @client1.puts "set 2 2 1000 0"
                @client1.puts ""
                @client1.puts "set 0"
            }
            y = Thread.new {
                @response1 = @client1.gets.chomp
                @response2 = @client1.gets.chomp
                @response3 = @client1.gets.chomp
                @response4 = @client1.gets.chomp
                @response5 = @client1.gets.chomp
            }
            x.join  
            y.join
        end

        it "success" do
            expect(@response1).to eq("STORED")
        end

        it "validate storage parameter not integer" do
            expect(@response2).to eq("CLIENT_ERROR, Flag, expiration time and bytes must be a Integer")
            expect(@response3).to eq("CLIENT_ERROR, Flag, expiration time and bytes must be a Integer")
        end

        it "noreply and success with empty message" do
            expect(@response4).to eq("STORED")
        end

        it "validate storage empty parameters" do
            expect(@response5).to eq("CLIENT_ERROR, Incorrect number of parameters")
        end
    end

    context 'add data' do
        before :all do
            x = Thread.new {
                @client1.puts "add 3 3 1000 3"
                @client1.puts "add"
                @client1.puts "add 3 5 100 8"
                @client1.puts "testing2"
                @client1.puts "add 5 sa 3 3"
                @client1.puts "add 4 4 3 2 nr"
                @client1.puts "nr"
                @client1.puts "add 5 4 sa 3"
                @client1.puts "add 0"

            }
            y = Thread.new {
                @response1 = @client1.gets.chomp
                @response2 = @client1.gets.chomp
                @response3 = @client1.gets.chomp
                @response4 = @client1.gets.chomp
                @response5 = @client1.gets.chomp
            }
            x.join  
            y.join
        end

        it "success" do
            expect(@response1).to eq("STORED")
        end

        it "key already exists" do
            expect(@response2).to eq("NOT_STORED")
        end

        it "validate storage and noreply" do
            expect(@response3).to eq("CLIENT_ERROR, Flag, expiration time and bytes must be a Integer")
            expect(@response4).to eq("CLIENT_ERROR, Flag, expiration time and bytes must be a Integer")
            expect(@response5).to eq("CLIENT_ERROR, Incorrect number of parameters")
        end
    end

    context 'replace data' do
        before :all do
            x = Thread.new {
                @client1.puts "replace 1 10 1000 7"
                @client1.puts "replace"
                @client1.puts "replace 5 3 1000 8"
                @client1.puts "testing2"
                @client1.puts "replace 2 sa 3 3"
                @client1.puts "replace 10 4 3 2 nr"
                @client1.puts "nr"
                @client1.puts "replace 5 4 sa 3"
                @client1.puts "replace 0"
            }
            y = Thread.new {
                @response1 = @client1.gets.chomp
                @response2 = @client1.gets.chomp
                @response3 = @client1.gets.chomp
                @response4 = @client1.gets.chomp
                @response5 = @client1.gets.chomp
            }
            x.join  
            y.join
        end

        it "success" do
            expect(@response1).to eq("STORED")
        end

        it "key doesnt exists" do
            expect(@response2).to eq("NOT_STORED")
        end

        it "validate storage and noreply" do
            expect(@response3).to eq("CLIENT_ERROR, Flag, expiration time and bytes must be a Integer")
            expect(@response4).to eq("CLIENT_ERROR, Flag, expiration time and bytes must be a Integer")
            expect(@response5).to eq("CLIENT_ERROR, Incorrect number of parameters")
        end
    end

    context 'append data' do
        before :all do
            x = Thread.new {
                @client1.puts "append 4 11 1000 7"
                @client1.puts " append"
                @client1.puts "append 5 10 1000 6"
                @client1.puts "append"
                @client1.puts "append 2 sa 3 3"
                @client1.puts "append 10 4 3 2 nr"
                @client1.puts "nr"
                @client1.puts "append 5 4 sa 3"
                @client1.puts "append 0"
            }
            y = Thread.new {
                @response1 = @client1.gets.chomp
                @response2 = @client1.gets.chomp
                @response3 = @client1.gets.chomp
                @response4 = @client1.gets.chomp
                @response5 = @client1.gets.chomp
            }
            x.join  
            y.join
        end

        it "success" do
            expect(@response1).to eq("STORED")
        end

        it "key doesnt exists" do
            expect(@response2).to eq("NOT_STORED")
        end

        it "validate storage and noreply" do
            expect(@response3).to eq("CLIENT_ERROR, Flag, expiration time and bytes must be a Integer")
            expect(@response4).to eq("CLIENT_ERROR, Flag, expiration time and bytes must be a Integer")
            expect(@response5).to eq("CLIENT_ERROR, Incorrect number of parameters")
        end
    end

    context 'prepend data' do
        before :all do
            x = Thread.new {
                @client1.puts "prepend 4 10 1000 8"
                @client1.puts "prepend "
                @client1.puts "prepend 5 10 1000 6"
                @client1.puts "prepend"
                @client1.puts "prepend 2 sa 3 3"
                @client1.puts "prepend 10 4 3 2 nr"
                @client1.puts "nr"
                @client1.puts "prepend 5 4 sa 3"
                @client1.puts "prepend 0"
            }
            y = Thread.new {
                @response1 = @client1.gets.chomp
                @response2 = @client1.gets.chomp
                @response3 = @client1.gets.chomp
                @response4 = @client1.gets.chomp
                @response5 = @client1.gets.chomp
            }
            x.join  
            y.join
        end

        it "success" do
            expect(@response1).to eq("STORED")
        end

        it "key doenst exists" do
            expect(@response2).to eq("NOT_STORED")
        end

        it "validate storage and noreply" do
            expect(@response3).to eq("CLIENT_ERROR, Flag, expiration time and bytes must be a Integer")
            expect(@response4).to eq("CLIENT_ERROR, Flag, expiration time and bytes must be a Integer")
            expect(@response5).to eq("CLIENT_ERROR, Incorrect number of parameters")
        end
    end

    context 'cas data' do
        before :all do
            x = Thread.new {
                @client1.puts "set 5 10 1000 3"
                @client1.puts "set"
                @client1.puts "cas 5 5 1000 3 9"
                @client1.puts "cas"
                @client1.puts "cas 5 6 1000 4 15"
                @client1.puts "test"
                @client1.puts "cas 6 6 1000 4 9"
                @client1.puts "test"
                @client1.puts "cas 2 sa 3 3 4"
                @client1.puts "cas 10 4 3 2 4 nr"
                @client1.puts "nr"
                @client1.puts "cas 5 4 sa 3 4"
                @client1.puts "cas 0"
            }
            y = Thread.new {
                @response1 = @client1.gets.chomp
                @response2 = @client1.gets.chomp
                @response3 = @client1.gets.chomp
                @response4 = @client1.gets.chomp
                @response5 = @client1.gets.chomp
                @response6 = @client1.gets.chomp
                @response7 = @client1.gets.chomp
            }
            x.join  
            y.join
        end

        it "success" do
            expect(@response1).to eq("STORED")
            expect(@response2).to eq("STORED")
        end

        it "key exists" do
            expect(@response3).to eq("EXISTS")
        end

        it "key dont exists" do
            expect(@response4).to eq("NOT_FOUND")
        end

        it "validate storage and noreply" do
            expect(@response5).to eq("CLIENT_ERROR, Flag, expiration time and bytes must be a Integer")
            expect(@response6).to eq("CLIENT_ERROR, Flag, expiration time and bytes must be a Integer")
            expect(@response7).to eq("CLIENT_ERROR, Incorrect number of parameters")
        end
    end
    
    context 'get data' do
        before :all do
            x = Thread.new {
                @client1.puts "get 0"
                @client2.puts "get 1 2"
                @client2.puts "get"
                @client2.puts "get 6 7 8"
            }
            y = Thread.new {
                @response1 = @client1.gets.chomp
                @response2 = @client1.gets.chomp
                @response3 = @client1.gets.chomp
                @response4 = @client2.gets.chomp
                @response5 = @client2.gets.chomp
                @response6 = @client2.gets.chomp          
                @response7 = @client2.gets.chomp
                @response8 = @client2.gets.chomp
                @response9 = @client2.gets.chomp
                @response10 = @client2.gets.chomp
            }
            x.join  
            y.join
        end

        it "one key success" do
            expect(@response1).to eq("VALUE 0 3 3")
            expect(@response2).to eq("set")
            expect(@response3).to eq("END")
        end

        it "another client two key success" do
            expect(@response4).to eq("VALUE 1 10 7")
            expect(@response5).to eq("replace")
            expect(@response6).to eq("VALUE 2 2 0")
            expect(@response7).to eq("")
            expect(@response8).to eq("END")
        end

        it "0 key" do
            expect(@response9).to eq("END")
        end

        it "keys dont exists" do
            expect(@response10).to eq("END")
        end
    end

    context 'gets data' do
        before :all do
            x = Thread.new {
                @client1.puts "gets 3"
                @client2.puts "gets 4 5"
                @client2.puts "gets"
                @client2.puts "gets 6 7 8"
            }
            y = Thread.new {
                @response1 = @client1.gets.chomp
                @response2 = @client1.gets.chomp
                @response3 = @client1.gets.chomp
                @response4 = @client2.gets.chomp
                @response5 = @client2.gets.chomp
                @response6 = @client2.gets.chomp          
                @response7 = @client2.gets.chomp
                @response8 = @client2.gets.chomp
                @response9 = @client2.gets.chomp
                @response10 = @client2.gets.chomp
            }
            x.join  
            y.join
        end

        it "one key success" do
            expect(@response1).to eq("VALUE 3 3 3 4")
            expect(@response2).to eq("add")
            expect(@response3).to eq("END")
        end

        it "another client two key success" do
            expect(@response4).to eq("VALUE 4 4 17 8")
            expect(@response5).to eq("prepend nr append")
            expect(@response6).to eq("VALUE 5 5 3 10")
            expect(@response7).to eq("cas")
            expect(@response8).to eq("END")
        end

        it "0 key" do
            expect(@response9).to eq("END")
        end

        it "keys dont exists" do
            expect(@response10).to eq("END")
        end
    end

    context 'expiration time' do
        before :all do
            x = Thread.new {
                @client1.puts "set 9 9 10 8"
                @client1.puts "exp time"
                time_now_plus10 = Time.now.to_i + 10
                @client1.puts "set 10 10 #{time_now_plus10} 18"
                @client1.puts "exp time unix time"
                sleep(6)
                @client1.puts "get 9 10"
                sleep(6)
                @client1.puts "get 9 10"
                @client1.puts "replace 9 9 10 8"
                @client1.puts "exp time"
                @client1.puts "replace 10 10 #{time_now_plus10} 18"
                @client1.puts "exp time unix time"
            }
            y = Thread.new {
                @response1 = @client1.gets.chomp
                @response2 = @client1.gets.chomp
                @response3 = @client1.gets.chomp
                @response4 = @client1.gets.chomp
                @response5 = @client1.gets.chomp
                @response6 = @client1.gets.chomp
                @response7 = @client1.gets.chomp
                @response8 = @client1.gets.chomp
                @response9 = @client1.gets.chomp
                @response10 = @client1.gets.chomp
            }
            x.join  
            y.join
        end

        it "set and check" do
            expect(@response1).to eq("STORED")
            expect(@response2).to eq("STORED")
            expect(@response3).to eq("VALUE 9 9 8")
            expect(@response4).to eq("exp time")
            expect(@response5).to eq("VALUE 10 10 18")
            expect(@response6).to eq("exp time unix time")
            expect(@response7).to eq("END")
        end

        it "wait and check" do
            expect(@response8).to eq("END")
        end

        it "check key deleted from cache" do
            expect(@response9).to eq("NOT_STORED")
            expect(@response10).to eq("NOT_STORED")
        end
    end
end