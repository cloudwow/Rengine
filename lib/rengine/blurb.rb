require 'digest/sha1'
require "uri"
require "ya2yaml"
require "not_relational/domain_model.rb"
module Rengine
  class Blurb < NotRelational::DomainModel
    
    property :id,:string,:is_primary_key=>true
    property :name,:string
    property :namespace,:string
    property :description , :string  
    
    has_many :BlurbWording,:blurb_id,:blurb_wordings
    index :namespace_and_name,[:namespace,:name],:unique=>true

    def Blurb.use_cache?
      return !@not_use_cache
    end
    def Blurb.use_cache=(val)
      @not_use_cache=!val
    end
    
    def Blurb.get(namespace,name)
      Blurb.find_by_namespace_and_name(namespace , name)

    end
    def get_wording(language=$language)
      wording=BlurbWording.find_by_blurb_and_language(self.id ,language)
      if !wording && language!='en'
        
        return self.get_wording('en')
        
      end
      return nil unless wording
      return wording.text
    end
    def set_wording(language,text)

      wording=  BlurbWording.find_by_blurb_and_language(self.id ,language)
      if !wording
        wording=BlurbWording.new
        wording.blurb_id=self.id
        wording.language_id=language
      end
      wording.text=text
      wording.save

      return wording
      
    end
    def Blurb.set_wording(namespace,name,language,text)
      blurb=Blurb.get(namespace,name)
      if !blurb
        blurb=Blurb.new
        blurb.name=name
        blurb.namespace=namespace
        blurb.save!
      end
      wording=blurb.set_wording(language,text)
      cache_key=Blurb.make_key(namespace,name,language)
      Nanikore::TimedCache.set(cache_key,text,:minutes=>30)
      wording
    end
    def Blurb.make_key(namespace,name,language_id)
      "BLURB:"+namespace+"-%-"+name+"-%-"+language_id
    end
    def Blurb.get_wording_no_cache(namespace,name,language_id='en',default_value=nil)
      b=Blurb.get(namespace,name)

      if b
        b.get_wording(language_id) || default_value || name
      else
        
        default_value || name  
      end

    end
    def Blurb.get_wording(namespace,name,language_id='en',default_value=nil)
      cache_key=Blurb.make_key(namespace,name,language_id)

      if Blurb.use_cache?
        result=Nanikore::TimedCache.get(cache_key,:minutes=>30){
          Blurb.get_wording_no_cache(namespace,name,language_id,default_value)
        }
      else
        result=Blurb.get_wording_no_cache(namespace,name,language_id,default_value)
      end


      result


      
    end

    def Blurb.environment_namespace
      $blurb_namespace || "likemachine.com"
    end
    def Blurb.l(name,
                args={})

      

      language=nil
      if args.has_key?(:language)
        language=args[:language]
      end
      language ||= $language
      if language==nil || language.empty?
        language = "en"
      end
      default_value=nil
      if args.has_key?(:default_value)
        default_value=args[:default_value]
      end
      default_value ||= name
      
      namespace=nil
      if args.has_key?(:namespace)
        namespace=args[:namespace]
      end
      namespace ||=self.environment_namespace

      result=Blurb.get_wording(namespace ,name,language ,default_value)

      #apply logic
      if !args[:no_logic] &&  result  && result.index('#{')


        #in a seperate binding, create variable for each arg
        value123=nil
        arg_binding=args[:binding] || binding
        
        args.each do |key, value|
          unless key==:binding 
            value123=value
            if args[:html_escape] && value && (!value.is_a?(String ) || !value.html_safe?)
              eval("#{key}=#{CGI.escapeHTML(value.to_literal)}",arg_binding)
            else
              eval("#{key}=#{value.to_literal}",arg_binding)
            end
          end
        end


        #escape quotes then eval blurb as double quoted string
        result=eval('"'+result.gsub("\"","\\\"")+'"',arg_binding)
      end

      return result;

    end
  end
end
