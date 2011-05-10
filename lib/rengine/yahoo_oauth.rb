module Rengine
  module YahooOauth

    
    def get_yahoo_oauth_consumer
      consumer = OAuth::Consumer.new("dj0yJmk9R0VUSG1RMm5RUnp2JmQ9WVdrOVRrWnVkM1JRTkdFbWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD03OQ--",
                                     "9e351398b5b037504b76da0f7285a7b18fcb39ff",
                                     {
                                       :site                 => 'http://address.yahooapis.com', 
                                       :scheme               => :header, 
                                       :realm                => 'yahooapis.com', 
                                       :http_method          => :get,
                                       :request_token_path   => '/oauth/v2/get_request_token', 
                                       :access_token_path    => '/oauth/v2/get_token', 
                                       :authorize_path       => '/oauth/v2/request_auth'}
                                     )
    end


    def initiate_yahoo_oauth(return_uri)
      consumer = get_yahoo_oauth_consumer
      request_token = consumer.get_request_token( {:oauth_callback => return_uri}, {})
      session[:oauth_secret] = request_token.secret
      #      return_uri=return_uri_left_part+"/return_from_google_oauth"
      redirect_to request_token.authorize_url + "&oauth_callback=#{return_uri}"
    end


    def handle_return_from_yahoo_oauth()
      request_token = OAuth::RequestToken.new(get_yahoo_oauth_consumer, params[:oauth_token], session[:oauth_secret])
      
      access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
      #      data=access_token.get("http://www-opensocial.googleusercontent.com/api/people/@me/@self").body

      pc_client = PortableContacts::Client.new "http://www-opensocial.googleusercontent.com/api/people", access_token

      


      provider_data={
        :oauth_id => pc_client.me.id,
        :oauth_provider => "YAHOO" ,
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

