module Rengine
  #the name is messed up
  class Webpage_cache_item

    attr_accessor  :html
    #web page title
    attr_accessor :title
    attr_accessor :layout_version
    #the blurbs that were used while rendering this item
    attr_accessor :blurb_names
    #view-code wrapped with this tag will not be interpreted until view-time
    attr_accessor :defer_tag
    #unique storage key
    attr_accessor :key
    attr_accessor :language

    #don't store this in s3.  use this only for runtime for "defer".   
    attr_accessor :second_pass_html
    
    def initialize(title,html,layout_version,defer_tag=nil,blurb_names=[])
      self.title=title
      self.html=html
      self.layout_version=layout_version
      self.blurb_names=blurb_names
      self.defer_tag=defer_tag
    end


    def to_s
      return  second_pass_html ||  html
    end
  end
end
