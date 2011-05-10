ENV["RAILS_ENV"]=ARGV[0] if ARGV.length>0

require 'config/boot.rb'
require 'config/environment.rb'
require 'initializer' 
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

ENV["RAILS_ENV"]=ARGV[0] if ARGV.length>0
puts "ENV[RAILS_ENV]=#{ENV["RAILS_ENV"]}"
OfflineWorker.instance.run

 
