require "json"
module Rengine
  
  #include this in your account controller
  module ActsAsAccountController
    def self.included(target)
      target.send(:include,GoogleOauth)
      target.send(:include,FacebookOauth)
      target.send(:include,YahooOauth)
      target.skip_before_filter :verify_authenticity_token
    end
    
    def validate_login(login)

      reg = /^[a-zA-Z0-9_-]{3,32}$/

      return (reg.match(login))? true : false

    end

    #create a new non-oauth user
    def signup
      
      
      login=params['login'] || ""
      login=login.strip.downcase
      ok=true
      @username_errors=[]
      @password_errors=[]
      if  login.length==0
        @username_errors << l("Username is required.")
      elsif  login.length<=3
        @username_errors << l("Username must be at least 3 characters.")
      elsif !validate_login(login)
        @username_errors <<  l("Invalid username.")
      end
      if !params['password'] || params['password'].length<3
        @password_errors << l("password must be at least 3 characters.")
      elsif !params['password2'] || params['password']!= params['password2']
        @password_errors <<  l("passwords don't match.")
      end

      if @username_errors.empty?
        existing_user=User.find(login.downcase,:consistent_read=>true)
        if existing_user
          @username_errors << l('That username is taken',:default_value => 'The username \'#{username}\' is already taken',:username => login)
        end
      end

      if @username_errors.empty? && @password_errors.empty?
        create_user(login,params['password'])
        redirect_to_target()
        return
      else
        @username_error= errors_array_into_html(@username_errors)
        @password_error= errors_array_into_html(@password_errors)
        render(:action => :login)

      end



    end

    #create a new user
    #oauth should pass nil password
    def  create_user(login,
                     password=nil,
                     options={})

      @user = User.create(login,password,options)

      start_session(@user)


      if new_user_handler
        Rengine::WorkRequest.create("#{new_user_handler}('#{@user.login.escape}','#{$language}')"); 
      end
      flash[:notice] = l("Thanks for signing up!")#l("Thanks for signing up!")
      @user
    end

    #non-oauth login
    def login
      if logged_in? && session[:return_to]
        redirect_to_target
      end
      if request.post?
        @referer = params[:referer] || request.referer

        self.current_user = User.authenticate(params[:login], params[:password])
        if logged_in?
          start_session(self.current_user)
          flash[:script] ||= ""  
          flash[:script] << "$('.loggedIn').fadeOut(200).fadeIn(200).fadeOut(200).fadeIn(100).fadeOut(100).fadeIn(100);"
          
          redirect_to_target(@referer)
        else
          flash[:warn]=l("Try again")
        end
      else

        @referer = request.referer 


      end
    end

    #list all users
    def list
      @users=User.find(:all,:order_by => :login )
    end

    #set remember-me and auth cookies
    def start_session(user)
      user.remember_me
      user.save()
      cookies[:auth_token] = { :value => user.remember_token , :expires =>Time.parse(user.remember_token_expires_at) }
      
      self.current_user = user

    end

    #TODO: what is this?
    def edit
      login_required
    end

    #TODO: what is this?
    def update_email
      login_required
    end



    #remove auth and remember me cookies
    def logout
      self.current_user.forget_me if logged_in?
      cookies.delete :auth_token
      reset_session
      flash[:notice] = "You have been logged out."
      goto_page=request.referrer  || "/"
      
      redirect_to(goto_page)
    end

    
    def change_password
      return unless request.post?
      begin
        if User.authenticate(current_user.login,params['current_password'])
          if params['new_password']==params['new_password_again']
            current_user.set_password params['new_password']
            
            current_user.save()
            flash[:notice] = l("password changed")
            
            
          else
            
            flash[:warning] = l("passwords do not match")
          end
        else
          flash[:warning] =  l("old password incrrect")
        end
      rescue => e
        flash[:warning] =  "#{e.message}"
        render :action => 'edit'
      end
    end


    #show upload form
    def upload_profile_image
      login_required
      store_action_origin
      
      @new_guid=NotRelational::UUID.generate.to_s
      
      port=''
      if request.port!=80
        port=":#{request.port.to_s}"
      end
      @describe_url="http://"+request.host+port+"/users/set_profile_image?new_guid=#{@new_guid}"
      @policy_text='{"expiration": "'+(Time.now.year+1).to_s+'-01-02T00:00:00Z",
  "conditions": [ 
    {"bucket": "'+$gc_bucket+'"}, 
    {"key": "uploads/'+@new_guid+'"},
    {"acl": "public-read"},
    {"success_action_redirect": "'+@describe_url+'"},
    ["starts-with", "$Content-Type", ""],
    ["content-length-range", 0, 100048576]
  ]
}'
      @policy = Base64.encode64(@policy_text).gsub("\n","")

      @signature= Base64.encode64(
                                  OpenSSL::HMAC.digest(
                                                       OpenSSL::Digest::Digest.new('sha1'), 
                                                       'nHeMPHjiWuXR3D/pzk1H+SvlqCcIMKFLwa2KhvmR', @policy)
                                  ).gsub("\n","")
      
      
      
    end
    
    def set_profile_image
      login_required
      
      @new_guid = params['new_guid']
      @old_guid== params['old_guid']
      if @new_guid
        raise "uploaded_profile_image_handler not set" unless uploaded_profile_image_handler

        Rengine::WorkRequest.create( "#{uploaded_profile_image_handler}('#{current_user.login.escape}','#{@new_guid.escape}')");

      elsif @old_guid
        raise "set_profile_image_handler not set" unless profile_image_handler

        Rengine::WorkRequest.create( "#{profile_image_handler}('#{current_user.login.escape}','#{@new_guid.escape}')");

      end
      
      flash[:notice]=l("Your file is being processed.  It will be visible within a few minutes")
      @return_url=get_and_clear_action_origin()
      
      
    end





    #oauth
    # 1.  link to likemachine/account/oauth_start
    # 2. redirect to facebook auth
    # 3. (user logs in ), facebook redirects back to LikeMachine/account/ouath_return
    # 4. LikeMachine redirects back to original_domain/account/oauth_domain_return
    #come back to this from LikeMachine after oauth steps are done
    #make new user if neccesary
    def oauth_domain_return

      @dest_path=URI.unescape(params["dest_path"])

      if params[:error]
        flash[:error]=l("There was an error while verifying your credentials.")
        session[:return_to] ||=@dest_path
        redirect_to @dest_path || session[:return_to]
        return
      end
      crypto=NotRelational::Configuration.singleton.crypto

      @provider_data_encrypted=params[:provider_data]
      @provider_data_yaml=crypto.decrypt(@provider_data_encrypted)
      @provider_data=YAML::load(@provider_data_yaml)
      @provider_id=@provider_data[:provider_id]
      @provider=@provider_data[:provider]

      expires=Time.at(@provider_data[:expires])
      if expires < Time.now.gmtime
        raise "not"
      end

      @found_user=User.find_by_oauth_lookup(@provider,@provider_id,:consistent_read=>true)


      if @found_user

        

        flash[:script] ||= ""  
        flash[:script] << "$('.loggedIn').fadeOut(200).fadeIn(200).fadeOut(200).fadeIn(100).fadeOut(100).fadeIn(100);"
        start_session(@found_user)
        redirect_to(@dest_path || session[:return_to])

      else
        #assign_login
        case @provider.upcase
        when "FACEBOOK"
          FacebookOauth.add_user_data(@provider_data)
          
        when "GOOGLE"
          GoogleOauth.add_user_data(@provider_data)
        when "YAHOO"
          YahooOauth.add_user_data(@provider_data)
        else
          raise "WTF? provider=#{@provider}"
        end
        @new_login=User.find_next_free_username(@provider_data[:full_name])

        @user=create_user(@new_login,
                          nil,
                          {
                            :oauth_id => @provider_id,
                            :oauth_provider => @provider ,
                            :first_name => @provider_data[:first_name],
                            :last_name => @provider_data[:last_name],
                            :full_name => @provider_data[:full_name],
                            :locale => @provider_data[:locale],
                            :gender => @provider_data[:gender]
                          }
                          )
        flash[:notice]=l("You have logged in as",:default_value=>'You have logged in as <b>#{name}</b>',:name => @user.full_name)

        redirect_to @dest_path || session[:return_to]


      end

    end

    #this should be called in the LikeMachine domain
    def oauth_start
      @provider= params[:provider]
      @dest_left=params[:dest_left]
      @dest_path=params[:dest_path]
      

      redirect_uri=self.oauth_return_uri(@provider,@dest_left,@dest_path)

      case @provider.upcase
      when "FACEBOOK"
        initiate_facebook_oauth(redirect_uri)
      when "GOOGLE"
        initiate_google_oauth(redirect_uri)
      when "YAHOO"
        initiate_yahoo_oauth(redirect_uri)
      else
        raise "WTF? unrecognized oauth provider"
      end

    end


    
    #come back to this in LikeMachine from facebook
    def oauth_return

      provider_data=nil

      @dest_left=URI.unescape(params[:dest_left])
      @dest_path=URI.unescape(params[:dest_path])      
      @provider=URI.unescape(params[:provider])
      @domain_return=self.oauth_domain_return_uri(@provider,@dest_left,@dest_path)
      
      begin
        
        case @provider.upcase
        when "YAHOO"
          provider_data=handle_return_from_yahoo_oauth
        when "GOOGLE"
          provider_data=handle_return_from_google_oauth


          
        when "FACEBOOK"
          provider_data=handle_return_from_facebook_oauth
        end

        provider_data[:provider] ||= @provider
      rescue
        provider_data=nil
      end
      if provider_data
        
        provider_data[:expires]=(Time.now.gmtime+3600).to_i

        crypto=NotRelational::Configuration.singleton.crypto
        @encrypted_data=crypto.encrypt(provider_data.to_yaml)


        redirect_to(@domain_return+"?provider_data=#{CGI.escape( @encrypted_data)}", :status => 302) 

      else
        
        redirect_to(@domain_return+"?error=true", :status => 302) 


      end
    end
  end
end
