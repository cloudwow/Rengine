require 'oauth'
require 'oauth/consumer'
require 'oauth/signature/rsa/sha1'
require "xmlsimple"
require 'portablecontacts'
module Rengine
  module GoogleOauth
    
    def get_oauth_consumer
      root= ""
      begin
        root = $workspace_root || ""
      rescue
      end
      consumer = OAuth::Consumer.new("oauth.likemachine.com","ioT0PfbXawBW9Ja9dUEFNsee",
                                     {
                                       :site => "https://www.google.com",
                                       :request_token_path => "/accounts/OAuthGetRequestToken",
                                       :access_token_path => "/accounts/OAuthGetAccessToken",
                                       :authorize_path=> "/accounts/OAuthAuthorizeToken",
                                       :signature_method => "RSA-SHA1",
                                       :private_key_file =>root+  "/workspace/davidknight/tools/pk-QG2ZAODW7AL4ZPC4JTHFQQGRWBZEOZZH.pem"})
    end


    def initiate_google_oauth(return_uri)
      consumer = get_oauth_consumer
      request_token = consumer.get_request_token( {:oauth_callback => return_uri}, {:scope => "http://www-opensocial.googleusercontent.com/api/people/@me/@self"})
      session[:oauth_secret] = request_token.secret
      #      return_uri=return_uri_left_part+"/return_from_google_oauth"
      redirect_to request_token.authorize_url + "&oauth_callback=#{return_uri}"
    end


    def handle_return_from_google_oauth()
      request_token = OAuth::RequestToken.new(get_oauth_consumer, params[:oauth_token], session[:oauth_secret])
      
      access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
      #      data=access_token.get("http://www-opensocial.googleusercontent.com/api/people/@me/@self").body

      pc_client = PortableContacts::Client.new "http://www-opensocial.googleusercontent.com/api/people", access_token

      


      provider_data={
        :oauth_id => pc_client.me.id,
        :oauth_provider => "GOOGLE" ,
        :full_name => pc_client.me.displayName,
        :first_name => pc_client.me.name[:givenName],
        :last_name => pc_client.me.name[:familyName]

      }
      
    end

    def self.add_user_data(provider_data)
      return
    end
  end
end
