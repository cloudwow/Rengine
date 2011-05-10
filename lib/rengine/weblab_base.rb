require "action_controller.rb"
require "action_view.rb"

module Rengine

  class WeblabBase
    #    include ApplicationHelper
    include ERB::Util
    
    def initialize(live_weblabs,
                   test_weblabs,
                   options={})
      @live_weblabs={}
      @weblabs={}
      live_weblabs.each{|w|
        @weblabs[w.id]=w
        @live_weblabs[w.id]=w
      }

      test_weblabs.each{|w|@weblabs[w.id]=w}

      if  @live_weblabs.length==0
        @live_weblabs={}
        @live_weblabs["default"]=test_weblab
        @weblabs["default"]=test_weblab
      end
      @options=options
      @default_oauth_uri=options[:oauth_uri]

      @renderers={}
    end

    def render_weblab(weblab,language,args={},options={})
      #actual_weblab=get_weblab(desired_weblab_id)
      puts "\t\tWEBLAB_BASE RENDER_WEBLAB #1"

      @oauth_uri=options[:oauth_uri] || args[:oauth_uri] ||@default_oauth_uri

      renderer=get_renderer(weblab,language)
puts "\t\tWEBLAB_BASE RENDER_WEBLAB #2"
      
      renderer_args=args.merge(:weblab => weblab,:oauth_uri => @oauth_uri)#,:blurb_binding => binding)
puts "\t\tWEBLAB_BASE RENDER_WEBLAB #3"


      unless options[:show_powerbar]
        renderer_args.merge!(:tags_to_delete => [:power])
      else
        renderer_args.merge!(:tags_to_unwrap => [:power])
        
      end
puts "\t\tWEBLAB_BASE RENDER_WEBLAB #4"

      #      unless options[:show_preruntime]==true
      #        renderer_args.merge!(:tags_to_delete => [:runtime])
      #      end

      renderer_args.merge!(:page_title => options[:page_title]) if options.has_key?(:page_title)

      

      result=renderer.render(language,renderer_args)
puts "\t\tWEBLAB_BASE RENDER_WEBLAB #5"


      @displayed_blurb_names=result.blurb_names
puts "\t\tWEBLAB_BASE RENDER_WEBLAB #6"
      
      result.to_s
    end

    def displayed_blurb_names
      @displayed_blurb_names
    end
    def get_renderer(weblab,language_id)
      if @renderers.has_key?(weblab.id)
        return @renderers[weblab.id]
      end
      result= Renderer.new(repair_layout(weblab.layout),:runtime_tags=>["runtime","power"],:tags_to_escape=>[],:template_name=>"weblab_layout:#{weblab.name}")
      @renderers[weblab.id]=result
      return result
    end

    def repair_layout(layout)
      layout.gsub!(/([^@]|^)current_user/,'\1@current_user')
      layout.gsub!('vn.globalcoordinate.com','vn.muonyes.com')
      layout
    end

    def get_weblab(weblab_id)
      actual_weblab=@weblabs[weblab_id]
      unless actual_weblab
        actual_weblab=get_random_weblab
      end

      return actual_weblab
    end
    
    def get_random_weblab
      random_choice=rand(@live_weblabs.length)
      return @live_weblabs[@live_weblabs.keys[random_choice]]
    end
    def oauth_uri(provider)
      if @oauth_uri && @oauth_uri.is_a?(Proc)
        @oauth_uri.call(provider)
      else
        @oauth_uri || "http://www.mulletsgalore.com"
      end
    end


    def time_ago_in_words(the_time)
      distance_of_time_in_words_to_now(the_time.getlocal)
    end


    def test_weblab
      w=Weblab.new(
                   :name => "test weblab",
                   :is_active => false,
                   :layout => test_layout,
                   :style_sheet => ""
                   )
    end
    
    def test_layout
      return  "
       <html>

 <head>
       <title><%=h( @page_title  )%></title>
     <script src=\"/javascripts/all5.js\" type=\"text/javascript\"></script>

</head>
<style type=\"text/css\">
html{
margin:0;
padding:0;
}
</style>
<body >
  <div id=\"modal\"></div>

<div style=\"background-color:#cce;margin:0;padding:0;\">
<h2>Rengine Site</h2>
<a href=\"/\">home</a>  | 
<%if @current_user %>
<a href=\"<%= @current_user.url %>\"><%=h @current_user.login%></a>  |
<% end %>
<a href=\"/account/logout\">log out</a>  | 
<a href=\"/account/login\">log in</a>
</div>
<div style=\"background-color:#cec;margin:0;padding:0;\">
<a href=\"/test/process_all_work\">process queue</a>  | 
<a href=\"/test/redo_user_pages\">redo user pages</a>  | 
<a href=\"/test/make_data\">make data</a>  |
<a href=\"/test/clear_data\">clear data</a>  
<a href=\"/test/scrape\">scrape</a>  
<a href=\"/admin/recent\">admin</a>  

</div>
<a href=\"<%=@oauth_uri%>\">
<img src=\"/images/facebook_login_btn.png\" width=\"154\" height=\"22\" alt=\"Login with Facebook\" /></a> 
<%if @current_user && @current_user!=:false %>
<div style=\"background-color:#ece;margin:0;padding:0;\">
<%= l('LOGGED IN AS') %> <%=@current_user.login%>
</div>
<% end %>
<% if @flash[:error] %><div class=\"error\"><%= @flash[:error] %></div><% end %>
<% if @flash[:warning] %><div class=\"warning\"><%= @flash[:warning] %></div><% end %>
<% if @flash[:notice] %><div class=\"notice\"><%= @flash[:notice] %></div><% end %>
<%=@content_for_layout%>
    
</body>
</html>"
    end

  end
end
