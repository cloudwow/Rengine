require "not_relational/domain_model.rb"
class String
  def ruby_escape
    return self.gsub("'","\\'")
  end
end

module Rengine
  class WorkRequest  < NotRelational::DomainModel
    include  ActsAsLogWriter

    property :work_hash,:string,:is_primary_key=>true
    property :deduplification_key,:string, :is_primary_key=>true
    property :is_recurring,:boolean,:is_primary_key=>true

    property :work,:text

    property :next_execution,:date
    property :seconds,:float

    property :lock, :string
    property :lock_expiration, :date
    def execute

      eval(self.work )
    end
    
    def WorkRequest.createRecurring(work,seconds,deduplification_key=nil,options={})
      work_request=find( [work.hash,
                          deduplification_key,
                          true],:consistent_read=>true)

      start_time= options[:start_time] ||  Time.now.gmtime
      if options.has_key?(:delay_seconds)
        start_time += options[:delay_seconds]
      end

      
      if work_request
        work_request.seconds=seconds

        if work_request.next_execution>start_time
          work_request.next_execution = start_time
        end

      else
        
        work_request=WorkRequest.new(
                                     :work => work,
                                     :work_hash => work.hash,
                                     :is_recurring => true,
                                     :seconds => seconds,
                                     :deduplification_key => deduplification_key,
                                     :lock => "init",
                                     :lock_expiration => (Time.now.gmtime()-60),
                                     :next_execution=>start_time
                                     
                                     )
      end
      work_request.save
      work_request
    end
    
    def WorkRequest.create(work,
                           deduplification_key=nil,
                           options={})


      #when should this start
      start_time= options[:start_time] ||  Time.now.gmtime
      if options.has_key?(:delay_seconds)
        start_time += options[:delay_seconds]
      end

      #does it exist already?
      work_request=find( [work.hash,
                          deduplification_key,
                          false],:consistent_read=>true)


      if work_request
        if work_request.next_execution > start_time
          old_lock=work_request.lock

          work_request.next_execution=start_time
          work_request.lock=rand().to_s
          begin
            work_request.save(  :expected => {:lock => old_lock})
            log_info "moved work request up to earlier time"

          rescue NotRelational::ConsistencyError
            log_info "someone else updated it.  let it go. it was probably executed"
          end


        else
          log_info "work request was already scheduled at an earlier time"
          log_info work.each_line{|l|log_info "\t\t#{l}"}
        end
      else
        work_request=WorkRequest.new(
                                     :work => work,
                                     :work_hash => work.hash,
                                     :is_recurring => false,
                                     :deduplification_key=>deduplification_key,
                                     :next_execution => start_time,
                                     :lock => "init",
                                     :lock_expiration => (Time.now.gmtime() -60) )
        work_request.save
        log_info("created  workrequest: #{work_request}")
      end

      work_request
    end

    def self.until_lock_or_nil(lock_until=nil)

      result = nil 
      while(result==nil)
        NotRelational::Repository.clear_session_cache

        begin
          result=yield
          break  unless result

          old_lock=result.lock


          if result.is_recurring
            result.next_execution=Time.now.gmtime+result.seconds
            result.lock_expiration=result.next_execution
          else
            result.lock_expiration=Time.now.gmtime+5*60
          end

          result.lock=rand().to_s
          result.save(  :expected => {:lock => old_lock})
          
        rescue NotRelational::ConsistencyError
          #try again
        rescue Exception => e
          log_error(e)
          result=nil
          break
        end
      end
      
      result
    end
    def WorkRequest.popRecurring()
      result=self.until_lock_or_nil{ find(:first,
                                          :params =>{
                                            :is_recurring => true,
                                            :next_execution =>
                                            NotRelational::AttributeRange.new(
                                                                              :less_than_or_equal_to =>
                                                                              Time.now.gmtime),
                                            :lock_expiration =>
                                            NotRelational::AttributeRange.new(
                                                                              :less_than_or_equal_to =>
                                                                              Time.now.gmtime)
                                          },
                                          :order_by => :next_execution,
                                          :consistent_read=>true)

        
      }
      
      result
    end



    def WorkRequest.popNonRecurring()
      result=self.until_lock_or_nil{ find(:first,
                                          :params =>{
                                            :is_recurring => false,
                                            :next_execution =>
                                            NotRelational::AttributeRange.new(
                                                                              :less_than_or_equal_to =>
                                                                              Time.now.gmtime),
                                            :lock_expiration =>
                                            NotRelational::AttributeRange.new(
                                                                              :less_than_or_equal_to =>
                                                                              Time.now.gmtime)
                                          },
                                          :order_by => :next_execution,
                                          :consistent_read=>true)
      }
      #delete
      result.destroy if result
      
      result
    end

    def WorkRequest.pop
      r=popNonRecurring || popRecurring;
    end

    def WorkRequest.executeOne()

      work_request=pop
      return nil unless work_request
      log_info("Executing workrequest: \n\t#{work_request.work.gsub("\n","\t\n")}\n")
      start_time=Time.now
      log_info("============================== Executing workrequest: ======================\n\t#{work_request.work[0..200].gsub("\n","\t\n")}")
      log_info "----------------------------------------------------------------------------"

result=nil
      begin

        result=WorkResult.new(work_request, work_request.execute )
      rescue => e
        log_error(e,:work => work_request.work)
        result= WorkResult.new(work_request,e)
      end
      log_info "    ***** work request took #{Time.now-start_time} seconds  *****"
      result
    end

    def WorkRequest.ruby_stringify(val)
      return "'"+val.gsub("'","\\'")+"'"
    end

    def to_s
      self.work
    end
  end
end
