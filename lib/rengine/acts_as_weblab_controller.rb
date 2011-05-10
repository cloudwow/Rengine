module Rengine

  module ActsAsWeblabsController 

    def self.included(target_class)
      target_class.before_filter :login_from_cookie
      target_class.before_filter :login_required, :only => [
                                                            :destroy,
                                                            :list,
                                                            :edit,
                                                            :update,
                                                            :create,
                                                            :make_clone,
                                                            :start_test,
                                                            :start_test,
                                                            :end_test ]
    end
    
    def stylesheet
      headers["Content-Type"] = "text/css; charset=utf-8" 
      render :text=> ApplicationController.current_weblab.stylesheet
    end
    
    def index
      list
      render :template => 'weblabs/list'
    end


    def list
      @request=request
      @the_weblabs = Weblab.find(:all,:order_by=>:created_date,:order=>:descending)
    end

    def show
      @the_weblab = Weblab.find(params[:id])
    end

    def new
      @the_weblab = Weblab.new
    end

    def put_stylesheet_in_s3(weblab)
      StaticFileManager.gzip_upload(weblab.stylesheet,"text/css; charset=utf-8" ,"stylesheets/#{weblab.id}")
    end

    def create
      
      if_administrator{
        @the_weblab = Weblab.new(params[:weblab])
        @the_weblab.created_date=Time.now.gmtime
        @the_weblab.save!
        put_stylesheet_in_s3(@the_weblab)
        flash[:notice] = 'Weblab was successfully created.'
        redirect_to :action => 'list'
        
      }
    end

    def edit
      
      @the_weblab = Weblab.find(params[:id])
      return unless  request.post?
      
      @the_weblab.name=params[:name]
      @the_weblab.adsense_channel=params[:adsense_channel]
      @the_weblab.layout=params[:layout]
      @the_weblab.stylesheet=params[:stylesheet]
      @the_weblab.save!
      put_stylesheet_in_s3(@the_weblab)

      
      flash[:notice] = 'Weblab was successfully updated.'
      clear_weblab_cache
      redirect_to :action => 'list'
      
      
    end
    def edit_light
      
      @the_weblab = Weblab.find(params[:id])
      return unless  request.post?
      
      @the_weblab.name=params[:name]
      @the_weblab.adsense_channel=params[:adsense_channel]
      @the_weblab.stylesheet=params[:stylesheet]
      @the_weblab.save!
      put_stylesheet_in_s3(@the_weblab)
      
      flash[:notice] = 'Weblab was successfully updated.'
      clear_weblab_cache
      redirect_to :action => 'list'
      
      
    end
    def make_clone
      
      if_administrator{
        parent = Weblab.find(params[:id])
        @the_weblab=Weblab.new
        @the_weblab.name="clone of "+parent.name
        @the_weblab.layout=parent.layout
        @the_weblab.stylesheet=parent.stylesheet
        @the_weblab.is_active=false
        @the_weblab.created_date=Time.now.gmtime
        @the_weblab.save!
        put_stylesheet_in_s3(@the_weblab)

        redirect_to :action => 'list'
      }
    end


    def destroy

      if_administrator{
        Weblab.find(params[:id]).destroy
                redirect_to :action => 'list'
      }

    end
    
    
    def toggle_live
      if_administrator{
        weblab = Weblab.find(params[:id])
        if weblab.is_active
          weblab.is_active=false
          
        else
          if weblab.adsense_channel==nil || weblab.adsense_channel.length==0
            render  :text=>'<span style="color:red">set adsense channel before starting test</span>',:no_wrap => true
            return
          end
          
          weblab.is_active=true
        end
        weblab.save
      }
      
      render  :text=>weblab.is_active.to_s,:no_wrap => true
    end
    def toggle_live
      self.if_administrator{
        weblab = Weblab.find(params[:id])
        if weblab.is_active
          weblab.is_active=false
          
        else
          if weblab.adsense_channel==nil || weblab.adsense_channel.length==0
            render  :text=>'<span style="color:red">set adsense channel before starting test</span>',:no_wrap => true
            return
          end
          
          weblab.is_active=true
        end
        weblab.save
        clear_weblab_cache
        render  :text=>weblab.is_active.to_s,:no_wrap => true
        return
      }
      render  :text=>"you are not an admin",:no_wrap => true

    end

    def toggle_test
      self.if_administrator{
        weblab = Weblab.find(params[:id])

        weblab.is_test=weblab.is_test!=true
        weblab.save
        clear_weblab_cache
      render  :text=>weblab.is_test.to_s,:no_wrap => true
        
      }
      
      
    end


  end
end
