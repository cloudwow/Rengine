module Rengine
  module ActsAsRengineController
    include UriUtil
    include ActionView::Helpers::DateHelper
    @@weblab_base=nil
    attr_accessor :page_title
    attr_accessor :no_wrap #do not wrap in weblab
    attr_accessor :renderer_params
    attr_accessor :show_powerbar
    attr_accessor :show_preruntime
    
    def self.included(base)

      base.extend(ClassMethods)

      #run this before each request
      base.before_filter :prepare_for_action

      #these methods will be available from views (but not rengine renderer)
      base.helper_method :current_user, :logged_in?, :oauth_return_uri,:oauth_uri, :l, :escape_path_element
      #      base.rescue_from Exception, :with => :on_error
      base.send(:include,ActsAsLogWriter)

    end
    
    #####
    # Class Methods to be 'extend'ed
    #####
    module ClassMethods

      #which class to use for users, should derive from RengineUser
      def user_class
        return @@user_class || Rengine::RengineUser
      end
      def user_class=(val)
        @@user_class=val
      end

      
      #Which set of blurbs to use for localaization. 
      def blurb_namespace
        raise "blurb_namespace not set" unless @@blurb_namespace
        @@blurb_namespace
      end
      def set_blurb_namespace(value)
        @@blurb_namespace=value
      end

      #the bucket to use for public files such as images, css, javascript
      def public_bucket=(value)
        class_variable_set("@@public_bucket",value)
      end
      def public_bucket
        x= class_variable_get("@@public_bucket")
        raise "public_bucket not set" unless x
        x
      end

      #storage bucket where prerendered views are stored.
      def render_cache_bucket=(value)
        class_variable_set("@@render_cache_bucket",value)
      end
      def render_cache_bucket
        x= class_variable_get("@@render_cache_bucket")
        raise "render_cache_bucket not set" unless x
        x
        #        raise "render_cache_bucket not set" unless @@render_cache_bucket
        #        @@render_cache_bucket
      end

      #the rendering engine
      def render_base
        @@rb ||=    Rengine::RenderBase.new(
                                            ::Rails.root.to_s +  "/app/views",
                                            #                                            Rengine::Language.enabled_language_ids,
                                            ["en"],#just use english and do runtime blurbs
                                            blurb_namespace,
                                            NotRelational::RepositoryFactory.instance.storage,
                                            render_cache_bucket,
                                            :logger => logger,
                                            :templates_directory=>  ::Rails.root.to_s+"/app/views")
        @@rb
      end
      def current_weblab
        $current_weblab
      end

    end #end class methods


    def on_error(e)
      
      log_error(e,:login => session[:user_login],:url=>request.env["REQUEST_URI"],:host => request_host)
      #      render :content_data => '<h1 style="color:red;text-align:center">Something bad happened.</h1>',:status=>500 
      

    end

    def request_host
      request.env["SERVER_NAME"]  || request.env["HTTP_HOST"]
    end

    def request_protocol
      
      protocol=nil
      if ENV["REQUEST_URI"]
        match=/([^:])+/.match(ENV["REQUEST_URI"])
        if match
          protocol=match[1]
        end
      end
      protocol || "http"
    end
    def request_port
      ENV["SERVER_PORT"] || 80
    end

    #for uri that will be sent to facebook
    #facebook will unescape it once
    def double_escape_path_element(value)
      escape_path_element(escape_path_element(value))
    end
    def request_uri_left_part

      match=/([^\/]+\/\/[^\/]+)\//.match(request.env["REQUEST_URI"])
      if match
        return match[1]
      else

        return self.request_protocol+"://"+self.request_host
      end
    end

    #url for login links and login button
    def oauth_uri(provider="FACEBOOK")
      dest= session["return_to"] || request.env["REQUEST_URI"] || "/"
      "#{oauth_uri_left_part}/account/oauth_start?provider=#{CGI.escape(provider)}&dest_left=#{CGI.escape(request_uri_left_part)}&dest_path=#{CGI.escape(dest)}"
    end

    #the url to return to after a authenticating with third party
    def oauth_return_uri(provider,
                         dest_left,
                         dest_path)
      
      #double escape to remove slashes
      "#{oauth_uri_left_part}/account/oauth_return/#{double_escape_path_element(provider)}/#{double_escape_path_element(dest_left)}/#{double_escape_path_element(dest_path)}"

    end

    #the url in the original domain to return to after likemachine auth
    def oauth_domain_return_uri(provider,
                                dest_left,
                                dest_path)
      dest_left+"/account/oauth_domain_return/#{double_escape_path_element(provider)}/#{double_escape_path_element(dest_path)}"

    end


    def oauth_uri_left_part
      $oauth_uri_left_part ||  "http://oauth.likemachine.com"
    end

    
    def is_tester?
      cookies['is_tester']=="true"
    end
    def tester_cookie=(val)
      cookies['is_tester']=  { :value => val.to_s , :expires =>Time.now+3600*24*365*10}
    end
    
    def is_administrator?
      current_user != :false && current_user.is_administrator
    end

    def if_administrator
      
      if current_user != :false && current_user.is_administrator
        yield
        return true
      else
        access_denied
        
      end

    end

    def if_administrator
      
      if current_user != :false && current_user.is_administrator
        yield
        return true
      else
        access_denied
        
      end

    end


    #TODO
    #if set will be called for each new user like such  new_user_handler(login,language)
    #will be called offline with WorkRequest
    def new_user_handler
      nil
    end

    #TODO
    #if set will be called for each new user like such  profile_image_handler(login,new_image_guid)
    #will be called offline with WorkRequest
    def set_profile_image_handler
      nil
    end
    def upload_profile_image_handler
      nil
    end
    
    def blurb_namespace
      self.class.blurb_namespace
    end
    
    #is the current user authenticated
    def logged_in?
      current_user != :false
    end

    
    def current_user_or_nil      
      return current_user if current_user && current_user!=:false
      return nil
    end

    # Accesses the current user from the session.
    #returns :false if not logged in
    def current_user
      
      if $local_session_user
        # #this global is so local scripts can set the #user before simulating requests
        @current_user=$local_session_user
        $local_session_user=nil #for one request at a time
      end
      @current_user ||= (session[:user_login] && self.class.user_class.find(session[:user_login])) || :false
      
    end
    
    # Store the given user in the session.
    def current_user=(new_user)
      session[:user_login] = (new_user.nil? || new_user.is_a?(Symbol)) ? nil : new_user.login
      @current_user = new_user
    end


    #weblab base used for wrapping views in weblab layout
    def weblab_base

      @@weblab_base = Nanikore::TimedCache.get("WeblabBase",:minutes=>93){
        Rengine::WeblabBase.new(
                                Rengine::Weblab.find_by_is_active(true),
                                Rengine::Weblab.find_by_is_test(true))
      }
      
    end

    #clear cache after a edit
    def clear_weblab_cache
      @@weblab_base =  Rengine::WeblabBase.new(
                                               Rengine::Weblab.find_by_is_active(true),
                                               Rengine::Weblab.find_by_is_test(true))
      $current_weblab=nil
      
    end

    #get ready to handle a new request
    def prepare_for_action
      # #don't save stuff between requests
      NotRelational::RepositoryFactory.instance.clear_session_cache
      @@page_blurbs =Set.new
      @renderer_params={}
      $current_weblab=nil
      @current_user=nil
      @displayed_blurb_names=Set.new
      #     if BannedIp.is_banned?(request.remote_ip)
      #       head(401)
      #       return
      #     end

      prepare_language_for_action
      prepare_powerbar_for_action
      prepare_rendermode_for_action
      prepare_weblab_for_action


      self.page_title="Rengine"
      self.no_wrap=false
      return true
    end

    def prepare_powerbar_for_action
      @powerbar_html=""
      @show_powerbar=false
      @show_preruntime=false
      if is_administrator?
        if params.has_key?('powerbar') 
          cookies['powerbar']=params['powerbar']
          if params['powerbar']=="on"
            @show_powerbar=true
          end
        elsif cookies["powerbar"]=='on'
          @show_powerbar=true
        end

        if params['preruntime']=="on"
          @show_preruntime=true
        end
      end
    end

    def browser_language
      enabled_languages=Nanikore::TimedCache.get("enabled_language_ids",:minutes=>90){
        Language.enabled_language_ids
      }
      request.preferred_language_from(enabled_languages) || request.compatible_language_from(enabled_languages) || "en"
    end
    def prepare_language_for_action
      headers["Content-Type"] = "text/html; charset=utf-8"
      
      if params[:language]
        $language=params[:language]
        cookies[:language]=$language

      else
        $language=cookies[:language] || browser_language
      end

      if $language.nil_or_empty?

        $language="en"
      end
      @language=$language

      
    end

    # Decide  which  weblab to use,
    # put weblab  in $current_weblab and also set cookies['weblab_id']
    # return the weblab
    def prepare_weblab_for_action
      $current_weblab=nil
      weblab_id=params['weblab_id'] || cookies['weblab_id']
      
      $current_weblab=weblab_base.get_weblab(weblab_id)
      cookies['weblab_id']=$current_weblab.id if $current_weblab.id != cookies['weblab_id']

      return $current_weblab

    end

    #decide which render mode to use
    #force_render, refresh, refresh_all
    def prepare_rendermode_for_action
      
      $render_translation_link=false
      
      if cookies["is_translating"] == 'true'
        login_from_cookie
        if logged_in?  &&  current_user.can_translate?
          $render_translation_link=true
          
        end
        
      end
      Rengine::Blurb.use_cache=!$render_translation_link

      if $render_translation_link
        $render_mode=:force_render
      end

      if params[:render_mode]
        render_base.render_mode_override =params[:render_mode].to_sym
      else
        render_base.render_mode_override=nil
      end

      @render_preruntime=("true"==params[:render_preruntime])
      
      


    end
    def render_base
      self.class.render_base
    end

    def build_renderer_params(content_for_layout,more={})



      
      {
        :is_tester=> is_tester?,
        :current_weblab => current_weblab,
        :flash => flash,
        :request => request,
        :page_title => self.page_title,
        :current_user=> current_user_or_nil,
        :content_for_layout => content_for_layout,
        :my_content => content_for_layout,
        :google_adsense_channel => current_weblab.adsense_channel,
        :show_powerbar => @show_powerbar,
        :show_preruntime => @show_preruntime,
        :oauth_uri => Proc.new{|provider|oauth_uri(provider)}

      }.merge(more).merge(@renderer_params)
    end

    def build_weblab_options(more={})
      {
        :show_powerbar => @show_powerbar,
        :show_preruntime => @show_preruntime

      }.merge(more)
    end

    def render_weblab(content_for_layout)
      puts "\tRENGINE RENDER_WEBLAB #1"

      html=weblab_base.render_weblab(
                                     current_weblab,
                                     @language,
                                     build_renderer_params(content_for_layout),
                                     build_weblab_options)
      puts "\tRENGINE RENDER_WEBLAB #2"

      html
    end
    #override the rails render method 
    def render(options = nil, extra_options = {}, &block) #:doc:
      @flash=flash
puts "RENGINE RENDER #1"
      options=interpret_rengine_options(options)
puts "RENGINE RENDER #2"
      #no layout
      super(options,extra_options,&block)
puts "RENGINE RENDER #3"
      unless self.no_wrap
puts "RENGINE RENDER #4a"
        
        
        txx=render_weblab(setUserJavascript+ self.response_body.join("\n"))
        puts "RENGINE RENDER #4b"

        #        puts "===========================\n"+txx.join("\n")+"\n!================================!"

        if $render_translation_link
          txx  << "\n<div style=\"background-color:#aaa;color:#0ff;\">\n"
          txx << translation_tool(@displayed_blurb_names)
          txx << "\n</div>\n"
        end
puts "RENGINE RENDER #5"

        self.response_body=txx
        
      end
    end

    # def add_weblab_and_tools(content_for_layout,options={})
    #   if response.content_type.index('html')
    #     erase_render_results
    
    #     content_for_layout=special_tools(content_for_layout)
    #     if self.no_wrap
    #       options[:text]=content_for_layout.to_s
    #     else
    
    #       options[:text]= render_weblab(content_for_layout)
    #     end
    
    #     render(options)
    #   end

    # end

    #look at the options that were passed to render
    #add/remove options to prepare for modofied render logic
    # :no_wrap=false turns off weblab layout wrapping
    # if :content_data is present, it is processed as a webpage cache item
    def interpret_rengine_options(options=nil)
      options ||={}

      #no_wrap means don't wrap with weblab layout
      if options[:no_wrap]
        self.no_wrap=options[:no_wrap]
        
      end
      if !self.no_wrap && !options.has_key?(:layout)
        #        options[:layout]='v2layout'
      end
      #content_data should be Webpage_cache_item structure
      if options[:content_data]
        content_data=options[:content_data]
        content_for_layout=nil
        if content_data.respond_to?(:title)
          
          self.page_title=content_data.title
        end
        if content_data.respond_to?(:html)
          #to_s so we get second pass
          content_for_layout= content_data.to_s
        else
          #it's just a string, assume it is the html
          content_for_layout=content_data.to_s

        end

        
        if content_data.respond_to?(:blurb_names)

          content_data.blurb_names.each{|b|@displayed_blurb_names.add b}

        end
        if @render_preruntime
          options[:text]=
            "<html><body><pre>" +
            CGI.escapeHTML(content_for_layout) +
            "<pre></body></html>"
        else
          #special tools=power tool, translation tool
          content_for_layout = special_tools(content_for_layout)

          options[:text] = content_for_layout.to_s

        end
        #remove special rengine option
        options.delete :content_data
        
      end
      return options
    end

    #this javascript will be put into every page so that client-side code can make use of it
    def setUserJavascript
      if logged_in?
        "<script type=\"text/javascript\">
likeMachineUserLogin='#{current_user.login}';
</script>";
      else
        ""
      end
    end

    #TODO
    def add_to_powerbar(html)
      @powerbar_html << html 
    end
    #TODO
    def special_tools(html)
      
      if !@no_wrap && @show_powerbar and current_user_or_nil
        
        html = "\n<div class=\"power powerbar\">\n"+@powerbar_html+"\n</div>\n"+html


      end


      html
    end

    def translation_tool(blurbs)
      TranslationTool.tools_for_all_blurbs(blurbs)

    end
    
    #current_weblab lives for duration of request
    def current_weblab
      $current_weblab||prepare_weblab_for_action
    end
    
    # #just for old weblabs

    #call access_denied if the user is not authenticated
    def login_required(&block)

      if !logged_in?
        login_from_cookie
      elsif !block.nil?
        block.call
      end
      
      logged_in?  ? true : access_denied
    end
    #redirect to login form
    def access_denied


      respond_to do |accepts|
        accepts.html do

          store_return_to

          flash[:warning]=l("You'll need to login first")


          redirect_to @login_url || "/account/login"


        end
        accepts.xml do
          headers["Status"]           = "Unauthorized"
          headers["WWW-Authenticate"] = %(Basic realm="Web Password")
          render :text => "Could't authenticate you", :status => '401 Unauthorized'
        end


      end

      false
    end

    def store_action_origin(val=previous_page)
      if !session[:action_origin]
        session[:action_origin] = val
      end
    end
    def get_and_clear_action_origin
      temp=session[:action_origin]
      session[:action_origin]=nil
      return temp
    end


    
    # We can return to this location by calling #redirect_to_target.
    def store_return_to()
      session[:return_to] = request.env["PATH_INFO"]
    end

    #go back to the page that user was trying to get to when before
    #being redirected to login
    def redirect_to_target(default=nil)
      
      goto_url=params[:return_to] || session[:return_to] || default || "/"
      
      session[:return_to] = nil
      redirect_to(goto_url)
    end
    # When called with before_filter :login_from_cookie will check for an :auth_token cookie and log the user back in if apropriate
    def login_from_cookie
      return unless cookies['auth_token'] && !logged_in?
      token=cookies['auth_token'].value
      token=token[0] if token.is_a? [].class
      user = self.class.user_class.find_by_remember_token(token)
      if user && user.remember_token

        user.remember_me
        self.current_user = user
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires =>Time.parse( self.current_user.remember_token_expires_at) }


      end
    end

    #translate using blurbs
    #args are gsubbed into the result whereever #{key} is found
    def l(name,
          args={})

      @@page_blurbs << name

      # unless self.no_wrap

      #   runtime_code="<%=l('#{name}',:language=>'#{$language}'"
      #   args.each do |k,v|
      #     #runtime l() will be weblab_base implementation
      #     runtime_code << ",:#{k.to_s} => #{v.to_literal} "
      #   end
      #   runtime_code << ") %>"
      #   "<runtime>"+CGI.escapeHTML(runtime_code)+"</runtime>"

      
      
      # else
      
      
      result=Blurb.l(name,args.merge(:binding=>binding));
      result.html_safe

      #      end
    end
    def time_ago_in_words(the_time)
      distance_of_time_in_words_to_now(the_time.getlocal)
      
    end

    def errors_array_into_html(array)

      if array==nil || array.empty?
        return nil
      else
        
        if array.length>1
          return "<ol>\n<li>\n"+array.join("</li>\n<li>")+"\n</li>\n</ul>"
        else
          return array[0]
        end
      end
      

    end

  end

end
