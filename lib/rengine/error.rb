
module Rengine
  class Error < NotRelational::DomainModel
    property :id,:string,:is_primary_key=>true
    property :host
    property :url
    property :login
    property :work
    property :message
    property :backtrace
    property :creation_time ,:date
    property :environment

    def self.create(*args)
      e=Error.new
      e.message=""

      if args[0].is_a? String
        e.message << args[0]+" ";
      end

      if args[0].is_a? Exception
        e.message << args[0].class.name  << ". "
      end
      if args[0].respond_to? :backtrace
        e.backtrace=args[0].backtrace.join("\n")
      end

      if args[0].respond_to? :message
        e.message << args[0].message
      end


      if args.last.is_a? Hash
        e.message << args.last[:message] if args.last.has_key? :message
        e.backtrace = args.last[:backtrace] if args.last.has_key? :backtrace
        e.host = args.last[:host] if args.last.has_key? :host
        e.environment = args.last[:environment] if args.last.has_key? :environment
        e.url  = args.last[:url] if args.last.has_key? :url
        e.login  = args.last[:login] if args.last.has_key? :login
        e.work  = args.last[:work] if args.last.has_key? :work
      end

      if defined? ENV
        e.host ||= ENV["HOSTNAME"]  || ENV["SERVER_NAME"] || ENV["HTTP_HOST"] || ENV["HOST"]
        e.environment ||=ENV["RAILS_ENV"]
      end
      e.creation_time=Time.now.gmtime
      e.save
      e
    end


    def to_s
      result = "ERROR"
      result << " HOST:#{self.host}" unless self.host.nil_or_empty?
      result << " ENVIRONMENT:#{self.environment}" unless self.environment.nil_or_empty?
      result << "\n"
      result = "\t"+self.message if self.message
      result << "\t\t"+self.backtrace.gsub("\n","\n\t\t") if self.backtrace
      result
    end
  end
end
