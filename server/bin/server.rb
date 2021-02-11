require_relative 'serverView.rb'

ServerView.new( ARGV[0], "0.0.0.0" ) # listen in all interfaces
