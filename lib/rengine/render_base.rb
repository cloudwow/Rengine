require 'ya2yaml'
require 'open-uri'
require 'yaml'
require 'uuid'
require 'uri'
require File.dirname(__FILE__) +'/renderer.rb'
require File.dirname(__FILE__) +'/page_cache_item.rb'


module Rengine

  require 'logger'
  class RenderBase


    
    attr_accessor :render_mode_override
    def initialize(
                   view_root,
                   languages,
                   namespace,
                   storage,
                   bucket_root,
                   options={})

      @renderer_extension_modules=[]
      @languages=languages
      @renderers={}
      @bucket_root=bucket_root
      @namespace=namespace
      @view_root=view_root
      @storage=storage

      @logger=options[:logger]
      unless @logger
        @logger = Logger.new(nil)
        @logger.level = options[:log_level] || Logger::WARN
      end
      @helpers=options[:helpers]


    end

    def extend_renderers(mod)
      @renderers.each do|key,renderer|
        renderer.extend_renderer(mod)
      end

      @renderer_extension_modules << mod
    end

    #rerender and cache this template/key combination for each language
    def refresh(template_name,key,args={},&prerender_block)
      #    @logger.debug("\trender_base.refresh(#{template_name},#{key})") if @logger
      result={}
      @languages.each do |language|
        result[language] = refresh_one_language(template_name,language,key,args,&prerender_block)
      end
      return result
    end
    #rerender and cache this template/key combination for ONE language
    def refresh_one_language(template_name,language,key,args={},&prerender_block)
      #    @logger.debug("\t\trender_base.refresh_one_language(#{template_name},#{language},#{key})") if @logger

      renderer=get_renderer(template_name)
      key ||= renderer.get_key(args)
      rendered=renderer.render(language,args,{:render_mode => :refresh},&prerender_block)
      put_page_into_s3(language,key,rendered)
      return rendered
    end

    def render(*args,&prerender_block)
      if args.length==5
        template_name,language,key,render_args,options=*args
      elsif args.length==4
        template_name,language,key,render_args=*args
      elsif args.length==3
        template_name,key,options=*args
      elsif args.length==2
        template_name,key,options=*args
      elsif args.length==2
        template_name,options=*args
      elsif args.length==1
        options=args[0]
        
      end
      options ||= {}
      

      
      template_name ||= options[:template_name]

      language ||= options[:language] ||  "en"
      key ||= options[:key]
      render_args ||= options[:render_args]
      render_args ||={}
      render_mode=render_mode_override || options[:render_mode]
      if render_mode
        if  render_mode !=:render && prerender_block!=nil

          template_name,key,render_args =  process_prerender_block(template_name,
                                                                   key,
                                                                   render_args,
                                                                   &prerender_block)
        end

        if render_mode ==:refresh_render ||
            render_mode ==:refresh_all
          return refresh(template_name,key,render_args)
        elsif render_mode  ==:refresh
          return refresh_one_language(template_name,language,key,render_args)
        elsif render_mode  ==:force_render
          return force_render(template_name,language,key,render_args)
        end
      end
      return read_or_render(template_name,language,key,render_args,&prerender_block)
    end

    #try the cache first.  if not in cache render and put in cache
    def read_or_render(template_name,language,key,render_args={},&prerender_block)
      #       @logger.debug("render_base.read_or_render(#{template_name},#{language},#{key})") if @logger
      #check cache

      renderer=nil
      unless key
        #try to generate the key
        renderer ||= get_renderer(template_name)

        key=renderer.get_key( render_args)
      end
      if key
        result=peek(language,key)
      end
      unless result

        template_name,key,render_args =  process_prerender_block(
                                                                 template_name,
                                                                 key,
                                                                 render_args,
                                                                 &prerender_block)
        
        renderer ||= get_renderer(template_name)
        result=renderer.render(language,render_args,{})
        put_page_into_s3(language,key,result)
      else
        #             @logger.debug("got it from cache") if @logger

      end
      return result
    end

    def force_render(template_name,language,key,args={},&prerender_block)
      
      renderer=get_renderer(template_name)
      renderer.render(language,args,{:render_mode => :force_render},&prerender_block)
    end
    
    def process_prerender_block(template_name,key,args,&block)
      unless block.nil?
        args=args.clone
        render_options={:template_name => template_name ,:key => key}
        result=block.call(args,render_options)
        template_name =render_options[:template_name] 
        key=render_options[:key]
      end
      return template_name,key,args
    end
    def peek(language,key)
      return nil unless key

      data = @storage.get(get_bucket_name(language),storage_key(key,language))
      return nil unless data
      result=data
      begin 
        result=YAML::load( data)
        
      rescue=> e
        
        #now change to yaml
        begin 
          data_without_bom = data[3..-1]
          
          result= YAML::load(data_without_bom) 
        rescue=> e
          
        end
      end
      #  || html.index("../../images/album")
      #     html=nil
      #     html=result if result.is_a? String
      #     html=result.html if result.respond_to?(:html)
      
      #     if html && (html.index("yuimenubar") || html.index("static.eyeblend.tv//media") || html.index("../../images/album_") )
      #       RAILS_DEFAULT_LOGGER.info("old messed up html found in storage.")
      #       #      return nil
      #     end

      return result
    end

    private

    def get_renderer(template_name)
#      renderer=@renderers[template_name];
#      return renderer if renderer
      path="#{@view_root}/#{template_name}"
      if File.exists?(path+".rhtml")
        path+=".rhtml"
      elsif File.exists?(path+".html.erb")
        path=path+".html.erb"
      else
        raise "Template not found: #{template_name}"
      end
      
      renderer=Renderer.new(File.open(path).read,
                            :render_base => self,
                            :template_name => template_name,
                            :helpers => @helpers,
                            :tags_to_escape => ["runtime"],
                            :templates_directory=>@view_root)
      @renderer_extension_modules.each do |mod|
        renderer.extend_renderer(mod)
      end
      @renderers[template_name]=renderer

      renderer
    end


    def get_bucket_name(language)
      # if language=='en'
      #   return @bucket_root
      # else
      #   return language+"-"+@bucket_root
      # end

      #moved language into the path, see storage_key
      return @bucket_root
    end
    


    


    def delete_s3_page(language,key)
      return unless key
      @storage.delete(get_bucket_name(language),storage_key(key,language))
    end


    def put_page_into_s3(language,key,cache_item)

      return unless key
      cache_item.key=key
      cache_item.language=language
      yaml=cache_item.ya2yaml(:syck_compatible => true)

      @storage.put(get_bucket_name(language),storage_key(key,language),yaml,{'Content-Type' => 'text/yaml' })
      return cache_item
    end

    def storage_key(renderer_key,language)

      if language=="en"
        return renderer_key
      else
        return language+"/"+renderer_key
      end

    end
  end
end
