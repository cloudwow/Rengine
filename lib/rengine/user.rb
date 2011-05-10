require 'digest/sha1'
require "uri"
require 'not_relational/geo.rb'
require "not_relational/domain_model.rb"

module Rengine
  module RengineUser
    def self.included(target)

      
      target.property :login ,:string,:is_primary_key=>true,:unique=>true,:required=>true
      target.property :remember_token ,:string,:unique=>true
      target.property :remember_token_expires_at ,:date
      target.property :last_login,:date
      target.property :email,:string,:unique=>true
      target.property :is_translater,:boolean
      target.property :is_administrator,:boolean
      target.property :created_at ,:date,:required=>true

      #if not facebook
      target.property :crypted_password 
      target.property :salt

      #from facebook
      target.property :oauth_provider
      target.property :oauth_id
      target.property :oauth_token
      target.property :oauth_secret
      target.property :first_name
      target.property :last_name
      target.property :full_name #ex. David Knight
      target.property :locale #ex. en-US
      target.property :gender,:enum,:values =>[:NONE,:MALE,:FEMALE]
      target.property :locale,:string
      target.index :oauth_lookup,[:oauth_provider,:oauth_id],:unique=>true

      target.class_eval(" class << self
alias_method :find_single_original, :find_single
end")

      target.extend(UriUtil)
      target.extend(ClassMethods)

      
    end

    module ClassMethods
      def create(login,password,other_props={})
        error_msg=""
        error_msg << "invalid login: #{login}" unless valid_login?(login)
        if password
          error_msg << "invalid password." unless valid_password?(password)
        end
        raise error_msg if error_msg.length>0
        
              props={
        :login => login,
        :last_login => Time.now.gmtime,
        :created_at => Time.now.gmtime
      }.merge(other_props)
        props[:full_name] ||= login
        result=new(props)
        result.remember_me
        if password
          result.set_password(password)
        end
        result.save
        return result
      end

      def find_or_create_by_email(email,name,other_props={})
        result=User.find_by_email(email,:consistent_read=>true)
        unless result
          username=find_next_free_username(name)
          result=create(username,nil,other_props)
          result.email=email
        else
          result.copy_attributes(other_props)
        end
        result
      end
      # true if
      # length>1
      # and
      # contains only alphanumeric and underscore
      def valid_login?(login)
        if !login || login.length<1
          return false
        end
        
        if ! /^[a-z0-9_]{2}(?:\w+)?$/i.match(login) # , :message=>'<i>Only letters(a-z), numbers(0-9), underscores(_) are allowed.</i>'
          return false
        end
        return true

      end
      # true if
      # length>=3
      def valid_password?(password)
        if !password || password.length<3
          return false
        end
        
        return true
      end
      # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
      def authenticate(login, password)
        u = find(login.downcase,:consistent_read=>true) # need to get the salt
        u && u.authenticated?(password) ? u : nil
      end
      def url_for(login)
        return "/"+storage_key(login)
      end
      def uri_login(login)
        escape_path_element(login.downcase)
      end
      def storage_key(login)
        return "user/#{uri_login(login)}"

      end

      def find_by_remember_token(token)
        find(:first,:params=>{:remember_token=>token},:consistent_read=>true)
        
      end
      def find_single(login, options)
        #overridden to downcase login
        #        find_single_original(login.downcase,options)
        login=login.downcase
        attributes=self.repository(options).find_one(self.table_name,[login],attribute_descriptions)
        if attributes && attributes.length>0

          attributes[:login]=login

          attributes[:repository]=self.repository(options)
          return istantiate(attributes,self.repository(options))
        end
        return nil

        
      end
      
      def recent(how_many=27)
        find(:all,:order_by=>:created_at,:order=>:descending,:limit=>how_many)
      end
      #arg might be already be a user or might be login
      def convert_arg_to_user(user_arg)
        user=nil
        if user_arg.respond_to?(:remember_me)
          user=user_arg
        else
          user=find(user_arg.downcase,:consistent_read=>true)
        end
        return user
      end

      def to_user
        self
      end

      #if its a user get the login, else assume it is already a login
      def convert_arg_to_login(user_arg)
        return nil unless user_arg
        if user_arg.respond_to?(:login)
          return user_arg.login
        else 
          return user_arg.to_s
        end
      end

      def find_next_free_username(base_username)
        base_username= base_username.gsub(" ","_")
        base_username= base_username.gsub("-","_")
        base_username= base_username.gsub(".","_")
        base_username= base_username.gsub("#","_")
        base_username= base_username.gsub(";","_")
        base_username= base_username.gsub("&","_")
        base_username= base_username.gsub("@","_")

        base_username= base_username.downcase
        index=0
        user = true
        while user
          if index>0
            username="#{base_username}#{index}"
          else
            username=base_username
          end
          user = User.find(username)
          index=index+1

        end
        username
      end

    end


    def can_translate?
      return is_administrator || is_translater
    end
    
    # Encrypts some data with the salt.
    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end

    

    def authenticated?(password)
      result=crypted_password == encrypt(password,self.salt)
      return result
    end

    def remember_token?
      if respond_to?(:remember_token_expires_at) 
        self.remember_token_expires_at &&  Time.now.utc < Time.parse(self.remember_token_expires_at) 
      end
      return false
    end

    # Set the fields required for remembering users between browser
    # remembers for two weeks
    def remember_me
      self.remember_token_expires_at = (Time.now+(2*3600*24*14)).utc.to_s
      self.remember_token            = encrypt("#{self.login}--#{self.remember_token_expires_at}",self.salt)
    end

    #unset remember_me
    def forget_me
      self.remember_token_expires_at = nil
      self.remember_token            = nil
      
    end
    
    
    def save(options={})
      self.login=self.login.downcase
      super(options)
      
    end
    
    def set_password(password)
      
      return if password.blank?
      self.salt= Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--#{rand}") 
      self.crypted_password= encrypt(password,salt)
    end

    def uri_login
      self.class.uri_login( self.login.downcase)
    end
    def storage_key
      self.class.storage_key(self.login)
    end
    def show_storage_key
      self.class.show_storage_key(self.login)
    end
    
    def url
      return self.class.url_for( self.login)
    end
    def on_activity
      self.last_login=Time.now.gmtime
      self.save!
    end
    
    def url
      return "/"+storage_key
    end
    
    def to_s
      self.login
    end

    

  end
end
