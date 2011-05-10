require 'digest/sha1'
require "uri"

require "not_relational/domain_model.rb"
module Rengine

  class Language < NotRelational::DomainModel
    property :id,:string,:is_primary_key=>true
    property :name,:string
    property :enabled ,:boolean  
    
    def Language.enabled_languages
      @@enabled_languages ||= Language.find(:all,:order_by => 'name',:params=>{:enabled=>true})
      return make_default if @@enabled_languages.length==0
      
      @@enabled_languages
    end
    def Language.languages

      @@languages||=Language.find(:all,:order_by => 'name')
      return make_default if @@languages.length==0
      
      @@languages

    end
    
    def Language.make_default
      english=Language.new
      english.name="English"
      english.enabled=true
      english.id="en"
      return [ english]
    end
    def Language.enabled_language_ids
      @@enabled_language_ids ||= Language.enabled_languages.map{|l| l.id}
      @@enabled_language_ids
    end
    def Language.for_each
      temp_language=$language
      
      for   language_id in   Language.enabled_language_ids
        $language=language_id
        yield
      end
      $language=temp_language
    end
    def Language.clear_cache
      @@enabled_languages = Language.find(:all,:order_by => 'name',:params=>{:enabled=>true}) 
      @@enabled_language_ids = Language.enabled_languages.map{|l| l.id}
      $languages=nil
      languages
    end

    def Language.get_closest_language(requested_id)
      default=nil
      result=nil
      Language.languages.each do |l|
        if l.id==requested_id
          result= requested_id
          break
        end
        #specific to generic match
        if l.id[0..1]==requested_id[0..1]
          default ||=l.id
        end
        #generic match to specific (overrides)
        if l.id ==requested_id[0..1]
          default = l.id
        end
      end
      result ||= default
      result

    end
  end
end
