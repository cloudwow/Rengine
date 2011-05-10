#! /usr/local/bin/ruby
# encoding: utf-8
require "action_view"
require "active_support"
#require "erb"
require "erubis"
require File.expand_path(File.dirname(__FILE__) +'/page_cache_item.rb')
module Rengine
  class Renderer < ActionView::Base
    #  include ApplicationHelper
    #  include ERB::Util
    #  include ActionController::UrlWriter
    include UriUtil
    include ActionView::Helpers::DateHelper

    attr_accessor :output_buffer
#    include ActiveSupport::CoreExtensions::Hash::Keys

    #this counter is for unit tests
    attr_reader :binding_rebuild_count

    attr_reader :escape_tags
    # template text is a nested template
    # the template is iterpreted once with localize blurbs
    # the result is another template that will be interpreted
    # with specific data
    #params
    # => template_text
    # => blurbs
    # => options
    #        :helpers => a collection of helpers to be "included"
    #        :default_language
    #        :render_base
    #        :template_home
    def initialize(template_text,options={})
      @renderer_extension_modules=[]

      @name=options[:template_name]
      @templates_root_dir= options[:templates_directory]# ||  "#{::Rails.root.to_s}/app/views"

      @output_buffer=""
      #unique tag for escaping post and pre  processing tags
      @ltag="!@@@##$$1212"
      @rtag="!723465hjf3!@#"

      @default_language=options[:default_language] || "en"


      @escape_tags= options[:tags_to_escape]  || []
      @runtime_tags= options[:runtime_tags]  || []


      #escape blocks that will be run at view time
      @template_text=template_text.clone
      @escape_tags.each do |etag|
        escape_tag_content( etag,@template_text)

        
      end

#      raise "need templates directory" unless options[:templates_directory]

      #escape all normal dynamic blocks for preprocessing
      @template_text=@template_text.gsub("<%",@ltag).gsub("%>",@rtag).gsub("<$","<%").gsub("$>","%>")
      
      #turn the setup block into a proc <## ##> into executable blocks
      @template_text=@template_text.gsub("<##","<% set_setup_proc{ ").gsub("##>","} %>")

      #turn the key block into a proc <## ##> into executable blocks
      @template_text=@template_text.gsub("<!!KEY","<% set_key_proc{ ").gsub("!!KEY>","} %>")


      @raw_template=compile(@template_text)
      #this hold variations of the template after it has been localized
      #into different languages, but before rendering
      @localized_templates={}
      @setup_proc=nil
      @key_proc=nil
      @render_base=options[:render_base]
      @template_name=options[:template_name]
      #this tag will be used to create non cachable dynamic blocks


      if options.has_key?(:helpers) && options[:helpers]!=nil
        options[:helpers].each do |helper|
          include helper
        end
      end
      
    end

    def extend_renderer(mod)

      @renderer_extension_modules << mod
      send(:extend,mod)
    end
    
    #render for each language and return as hash
    def render_batch(languages,argsx={},callback_options={})
      clear
      result={}
      
      frame_binding=    create_binding(argsx,callback_options)
      languages.each do |language|
        template=prep_template(language,frame_binding)
        apply_view_setup(frame_binding)
        result[language]= render_impl(template,language,frame_binding)
      end
      result
    end

    def get_key(argsx={},callback_options={})
      frame_binding=    create_binding(argsx,callback_options)
      template=prep_template("en",frame_binding)


      if @key_proc
        eval "@key_proc.call",frame_binding
      else
        nil
      end

      
    end
    #render for a particular language
    def render(language,argsx={},callback_options={})
      @language=language
      if argsx==nil || argsx.is_a?(String)
        #       this happen if template calls render instead of render_partial
        raise "bad args to render.  did you mean to call render_partial?"
      end





      tags_to_delete = argsx[:tags_to_delete] 
      tags_to_unwrap = argsx[:tags_to_unwrap] 

      @blurb_binding=argsx[:blurb_binding]
      @oauth_uri=argsx[:oauth_uri]
      
      clear
      frame_binding=    create_binding(argsx,callback_options)
      template=prep_template(language,frame_binding)


      apply_view_setup(frame_binding)
      
      result=render_impl(template,language,frame_binding)


      
      runtime_tags= argsx[:runtime_tags] || @runtime_tags
      
      unless runtime_tags.nil_or_empty? && tags_to_delete.nil_or_empty?
        render_second_pass(result,frame_binding,language,runtime_tags,tags_to_delete,tags_to_unwrap)
      end
      result
      
    end

    #clear variables used during render
    def clear
      @output_buffer=""
      @binding_rebuild_count=0
      @xyz123page_blurbs=Set.new
      @args=nil
    end

    #get or create a localized template
    def prep_template(language,frame_binding)

      template=@localized_templates[language]
      @language=language
      eval("@language='#{language}'",frame_binding)
      
      unless template
        local_template_text=@raw_template.result(frame_binding)
        local_template_text=local_template_text.gsub(@ltag,"<%")
        local_template_text=local_template_text.gsub(@rtag,"%>")

        template=compile(local_template_text)
        @localized_templates[language]=template unless  is_development?
      end
      template
      
    end

    
    def is_development?
      ENV["RAILS_ENV"] && ENV["RAILS_ENV"].index("dev")!=nil
    end

    def create_binding(argsx,callback_options={})

      @args123=argsx || {}
      @options123=callback_options
      
      b=binding

      if @args123
        @args123.each do |arg,val|
          code="@#{arg}=@args123[:#{arg}]"
          eval(code,b)
        end
        
      end
      
      eval('   @optionsABC=Marshal::load(Marshal.dump(@options123))
              @xyz123page_blurbs=Set.new
              def render_partial(template_name,key,args={})
                @optionsABC[:render_mode]=:render if @optionsABC[:render_mode]==:refresh_render ||@optionsABC[:render_mode]==:refresh_all
                #partials should not run second pass.  that will be done at the end
                result=@render_base.render(template_name,@language,key,args,@optionsABC.merge(:runtime_tags=>[],:tags_to_delete=>[],:tags_to_unwrap=>[]))
                @xyz123page_blurbs.merge(result.blurb_names)

                result
              end

              #put it into the global namespace
              @renderer_extension_modules.each do |mod|


                Object.send(:include,mod)
              end


              ',  b)



               return b
    end

   def set_arg(name,value)
     @args123[:name]=value
   end


   #call the setup proc if it has not been called.
   #for a batch of multiple language renders, the setup proc should
   #only get executed once
   def apply_view_setup(frame_binding)
     already_processed=eval "@frame_binding_setup_complete",frame_binding
     unless already_processed
       @binding_rebuild_count+=1
       if @setup_proc
         eval "@setup_proc.call",frame_binding
       end
       eval "@frame_binding_setup_complete=true",frame_binding
     end
   end

   def with_language(frame_binding,language='en')
     @language=language
     temp_language=$language
#     $language=@language
     begin
       
       eval "@language='#{language}'",frame_binding
       yield
     ensure
 #      $language=temp_language
     end
     
   end
   
   def escape_tag_content(tag,html)
     #i=case insensitive
     #m=dot matches new line
     regex=/(<\s*#{tag}\s*>)(.*?)(<\/#{tag}\s*>)/im


     html.gsub!( regex ) do |runtime_code|
       $1 +
         CGI.escapeHTML($2) +
         $3
       
     end
     
   end
   def unescape_tag_content(tag,html)
     regex=/(<\s*#{tag}\s*>)(.*?)(<\/#{tag}\s*>)/im

     html.gsub!( regex ) do |runtime_code|

       CGI.unescapeHTML($2) 

       
     end

   end
   def delete_tag_and_content(tag,html)

     #i=case insensitive
     #m=dot matches new line
     regex=/(<\s*#{tag}\s*>)(.*?)(<\/#{tag}\s*>)/im


     html.gsub!( regex ) do |runtime_code|
       ""
     end
     


   end
   def unwrap_tag_content(tag,html)

     #i=case insensitive
     #m=dot matches new line
     regex=/(<\s*#{tag}\s*>)(.*?)(<\/#{tag}\s*>)/im


     html.gsub!( regex ) do |runtime_code|
       $2
     end
     


   end
   def render_second_pass(cache_item,frame_binding,language,runtime_tags=nil,tags_to_delete=nil,tags_to_unwrap=nil)
     @is_runtime=true
     eval "@is_runtime=true",frame_binding
     eval "@language='#{language}'",frame_binding
     eval "$language='#{language}'",frame_binding


     result=nil

     pass_template_text= cache_item.html



     if tags_to_delete
       tags_to_delete.each do |tag|

         delete_tag_and_content(tag,pass_template_text)
       end
     end

     if tags_to_unwrap
       tags_to_unwrap.each do |tag|

         unwrap_tag_content(tag,pass_template_text)
       end
     end

     if runtime_tags
       runtime_tags.each do |rtag|
         unescape_tag_content(rtag,pass_template_text)
       end
     end

     pass_template=Erubis::Eruby.new(pass_template_text)
     
     with_language(frame_binding,cache_item.language) do
       
       result= pass_template.result(frame_binding)
     end

     cache_item.second_pass_html=result
     
   end
   def render_impl(template,language,frame_binding)
     @is_runtime=false
     eval "@is_runtime=false",frame_binding

     with_language(frame_binding,language) do
       begin
         
         eval "@language='#{language}'",frame_binding
         html=template.result(frame_binding).utf_or_die!
         @xyz123page_blurbs=eval("@xyz123page_blurbs",frame_binding)

         html.gsub!("<%","&lt;%")#do this to prevent ruby injection into
         #later steps
         title=eval "@page_title",frame_binding
         return Webpage_cache_item.new( title,
                                        html,
                                        2,
                                        nil,
                                        @xyz123page_blurbs)

       rescue => e
         raise "Exception while rendering template
Exception message: #{e.message}
Exception backtrace: #{e.backtrace.join("\n")}
Template: #{template.src[0..200]}"
       end
     end #with_lang
   end

   # def load_widgets(widgets,use_cache=false)
   #   wl=WidgetLoader.new
   #   wl.load(widgets,use_cache,@language)
   # end

   def time_ago_in_words(the_time)
     if @is_runtime
       distance_of_time_in_words_to_now(the_time.getlocal)
     else
       
       "<runtime>"+CGI.escapeHTML("<%=distance_of_time_in_words_to_now(Time.at(#{the_time.to_i}).getlocal) %>")+"</runtime>"
      
     end
     
   end


   def oauth_uri(provider)

     if @oauth_uri && @oauth_uri.is_a?(Proc)
       @oauth_uri.call(provider)
     else
       @oauth_uri ||      "<runtime>"+CGI.escapeHTML("<%= oauth_uri('#{provider.gsub("'","\\'")}) %>")+"</runtime>"
     end
   end
   
   def l(name,args={})
     if @is_runtime
       begin
         
         language=args[:language]
         language=@language if language.nil_or_empty?
         language=$language if language.nil_or_empty?
         result=Rengine::Blurb.l(name,args.merge(:binding=>@blurb_binding || binding,:language=>language,:html_escape=>true))
       rescue Exception => e
         puts e.to_s
         raise e
       end
       result.html_safe
       
     else
       
       @xyz123page_blurbs ||=Set.new
       @xyz123page_blurbs << name # if @xyz123page_blurbs

     
       runtime_code="<%=l('#{name}'"
       args.each do |k,v|
         #runtime l() will be weblab_base implementation
         runtime_code << ",:#{k.to_s} => #{v.to_literal}"
         if v && v.is_a?(String)&& v.html_safe?
           runtime_code << ".html_safe"
         end
       end
       runtime_code << ") %>"
       "<runtime>"+CGI.escapeHTML(runtime_code)+"</runtime>"
     end
   end

   # #localize some text
   # def l(name,  args={})

   #   @xyz123page_blurbs << name  if @xyz123page_blurbs

   #   args[:language]=@language
   
   #   result=@renderer_blurb_map.get(name,@language)
   
   #   if args && result
   #     value123=nil
   #     arg_binding=binding
   #     args.each do |key, value|
   #       value123=value
   #       eval("#{key}=value123",arg_binding)
   #     end
   #     result=eval('"'+result.gsub("\"","\\\"")+'"',arg_binding)
   #   end      
   
   
   #   return result || default_value;
   
   # end

   #list of blurbs that were used during last render
   def displayed_blurb_names
     temp=@xyz123page_blurbs.sort
     @xyz123page_blurbs=Set.new
     return temp
     
   end
   
   def set_setup_proc(&block)
     @setup_proc=block
     
   end
   def set_key_proc(&block)

     @key_proc=block
     
   end
   #TODOall of the methods below should be refactored away
   def current_weblab
     return $current_weblab
   end
   def current_user
     return @current_user
   end
   def request
     return @request
   end
   # def render_my_partial(path,binding,partial_arguments={})
   #   puts "rendering partial #{path}"
   #   with_output_buffer{
   #     @partial_arguments=partial_arguments
   #     return get_partial_template(path).result(binding)
   #   }
   # end

   # def get_partial_template(path)
   #   if !$partial_templates
   #     $partial_templates={}
   #   end
   #   if $partial_templates[path]
   #     return $partial_templates[path]
   #   end
   #   template_text=File.open(  "#{templates_root_dir}/#{path}",'r').read
   #   template=compile( template_text)
     
   #   $partial_templates[path]=template unless is_development?
   #   return template
   # end  
   def protect_against_forgery?
     return false
   end
   def url_for(options = {}, *parameters_for_method_reference) 
     case options
     when String
       options


     when Hash
       url=""
       if options[:controller]
         url << "/"+options[:controller].to_s
       end
       if options[:action]
         url << "/"+options[:action].to_s
       end
       if options[:id]
         url << "/"+options[:id].to_s
       end
       first_param=true
       options.each{|key,value|
         if key!=:controller and key!=:action and key!=:id
           if first_param
             url << "?"
           else
             url << "&"
           end
           first_param=false
           url<< CGI.escape(key.to_s)
           url<< "="
           url<< CGI.escape(value.to_s)
         end
       }
       return url
     end

   end

   #stolen from rails code
   def compile(template_source)
     # if RUBY_VERSION >= '1.9'
     #   template_source=template_source.sub(/\A#coding:.*\n/, '') 
     # end
     # ::ERB.new("<% __in_erb_template=true %>#{template_source}", nil, "-", '@output_buffer')

     Erubis::Eruby.new(template_source.utf_or_die!)
     
   end

 end
   end
