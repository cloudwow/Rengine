require "logger"
module Rengine
  module ActsAsLogWriter
    def self.included(base)
      @@logger=nil
      base.extend(ClassMethods)
    end

    def logger
      self.class.logger
    end

    def logger=(l)
      self.class.logger=l
    end

    def log_debug(msg)
      self.class.log_debug(msg)
    end

    def log_warn(msg)
      self.class.log_warn(msg)
    end

    def log_info(msg)
      self.class.log_info(msg)
    end

    
    def log_error(*args)
      self.class.log_error(*args)
    end

    module ClassMethods
      def logger
        unless @logger
          if defined?(   ::Rails.logger    )
            @logger ||=  ::Rails.logger
          else

            @logger ||= Logger.new(STDOUT)
            @logger.level = Logger::INFO

          end
        end
        @logger
      end

      def logger=(l)
        @logger=l
      end

      def log_debug(msg)
        begin
          self.logger.debug(msg)
        rescue Exception => e
          logging_error(e)
          @logger.error("ORIGINAL LOG MSG: #{msg}")
        end

      end

      def log_warn(msg)
        begin
          self.logger.warn(msg)
        rescue Exception => e
          logging_error(e)
          @logger.error("ORIGINAL LOG MSG: #{msg}")
        end

      end

      def log_info(msg)

        begin
          self.logger.info(msg)
        rescue Exception => e
          logging_error(e)
          @logger.error("ORIGINAL LOG MSG: #{msg}")
        end

      end

      def log_error(*args)
        begin
          e=nil
          begin
            e=Error.create(*args)
          rescue
            #ignore unsaved Error
          end
          msg=e.to_s if e
          msg=args.inspect unless e
          logger.error(e.to_s)
        rescue Exception => e
          logging_error(e)
          @logger.error("ORIGINAL LOG MSG: #{msg}")
        end
      end

      def logging_error(e)
        @logger = Logger.new(STDOUT)
        @logger.error("Exception while logging.  Switching to STDOUT.  Error was #{e.to_s}")
        
      end
    end
  end
end
