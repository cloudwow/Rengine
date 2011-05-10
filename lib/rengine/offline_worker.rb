
require 'open-uri'
require 'yaml'
require 'cgi'
require 'singleton'
module Rengine

  class OfflineWorker
    class QuitException < Exception
    end
    include Singleton
    include  ActsAsLogWriter


    def initialize()
      
    end
    
    def enqueue(klass,method,args)
      enqueue_impl(@queue,klass,method,args)
    end
    
    def enqueue_maintainence(klass,method,*args)
      enqueue_impl(@queue_maintainence,klass,method,*args)
    end

    def quit_on_int 
      puts "Quitting on interrupt signal." 
      exit 
    end

    def quit_on_quit 
      puts "U sure killed me guud!" 
      exit 
    end

    
    def run
      begin
      while true
        run_one_round
        sleep 5
        
      end
      rescue QuitException => e
        puts "caught QuitException.  quitting"
      end
    end
    
    def run_one_round
      NotRelational::RepositoryFactory.instance.clear_session_cache

      process_work_items
    end

    def stop
    end

    
    def process_work_items
      results=[]
      quit=false
      while !quit
        
        one_result=process_one_work_item
        break if one_result.nil?
        results << one_result
        NotRelational::RepositoryFactory.instance.clear_session_cache

        trap("KILL") {log_info "worker quitting on KILL";quit=true} 
        trap("TERM") {log_info "worker quitting on TERM";quit=true} 
        trap("QUIT") {log_info "worker quitting on QUIT";quit=true} 
        trap("INT") {log_info "worker quitting on INT";quit=true} 
        
      end
      raise QuitException "Quitting" if quit
      results

    end
    
    def process_one_work_item
      return WorkRequest.executeOne()
    end

    private

    def self.unmarshal_call(klass_name,method,*marshalled_args)
      args=[]
      marshalled_args.each do |ma|
        args << Marshal.load(ma)
      end
      klass=eval "#{klass_name}"
      klass.send(method,*args)
    end
    
    def enqueue_impl(queue,klass,method,args)
      #           message={}
      #           message[:klass]=klass.name
      #           message[:method]=method
      #           message[:args]=args
      #           message[:key]=:execute_on_worker


      message="OfflineWorker.unmarshal_call(:#{klass.name},:#{method}"
      args.each{|arg|
        message << ", " 
        message << safe_ruby_string(Marshal.dump(arg))

      }
      message << ")"
      WorkRequest.create(message)
    end

    def safe_ruby_string(text)
      return "'"+text.to_s.gsub(/[']/, '\\\\\'')+"'"
    end

  end
end
