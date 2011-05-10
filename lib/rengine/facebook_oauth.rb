require 'oauth'
require 'oauth/consumer'
require 'oauth/signature/rsa/sha1'
require "xmlsimple"
require 'portablecontacts'
module Rengine
  module FacebookOauth
    
    def validate_oauth_code(provider,code,redirect_uri)
      secret="b23fb72718fbf61be43ece795edc3ae6"

      access_token_uri="https://graph.facebook.com/oauth/access_token?"+
        "client_id=149049185110920"+
        "&client_secret=#{CGI.escape secret}"+
        "&redirect_uri=#{CGI.escape(redirect_uri)}"+
        "&code=#{CGI.escape(code)}"
      facebook_data_result=nil
      begin
        open(access_token_uri, "User-Agent" => "likemachine_auth",
             "Referer" => "ruby code") { |f|
          facebook_data_result = f.read
        }
      rescue OpenURI::HTTPError
        return nil
      end
      if match=/access_token=(.+)&expires=(.+)/.match(facebook_data_result)
        access_token=match[1]
        expires=match[2]
        return access_token
      else
        return nil
      end


      
    end


    def initiate_facebook_oauth(return_uri)
      redirect_to("https://graph.facebook.com/oauth/authorize?client_id=149049185110920&redirect_uri=#{CGI.escape(return_uri)}", :status => 302)
    end




    def handle_return_from_facebook_oauth()


      @code=params[:code]

      @dest_left=URI.unescape(params[:dest_left])
      @dest_path=URI.unescape(params[:dest_path])

      redirect_uri=self.oauth_return_uri(@provider,@dest_left,@dest_path)
      if validate_oauth_code(@provider,@code,redirect_uri)

        @domain_return=self.oauth_domain_return_uri(@provider,@dest_left,@dest_path)



        provider_id=/-([^-]+)\|/.match(@code)[1]


        provider_data =     {
          :provider => "FACEBOOK",
          :provider_id =>provider_id
        }
        return provider_data
      else
        return nil
        
      end
    end

    def self.add_user_data(provider_data)
      puts "=========================================\n#{provider_data.to_yaml}"
      
      facebook_data_uri="https://graph.facebook.com/#{provider_data[:provider_id]}"

      facebook_data_result=nil
      open(facebook_data_uri, "User-Agent" => "likemachine_auth",
           "Referer" => "ruby code") { |f|
        facebook_data_result = f.read
      }
      puts "=========================================\n#{facebook_data_result.to_yaml}"
      
      facebook_data=JSON.parse(facebook_data_result)
            puts "=========================================\n#{facebook_data.to_yaml}"
      provider_data[:gender]= facebook_data["gender"].upcase.to_sym
      provider_data[:full_name]= facebook_data["name"]
      provider_data[:first_name]= facebook_data["first_name"]
      provider_data[:last_name]= facebook_data["last_name"]
      provider_data[:locale]= facebook_data["locale"]
      puts "=========================================\n#{provider_data.to_yaml}"
puts "=================================="

    end
  end
end
