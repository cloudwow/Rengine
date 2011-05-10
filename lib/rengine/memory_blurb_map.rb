module Rengine

  class MemoryBlurbMap
    def initialize(default_language='en')
      @default_language=default_language
      @blurbs={}
    end
    def get(key,language,default_value=key)
      blurb=@blurbs[key]
      return default_value unless blurb
      blurb[language] || blurb[@default_language] || key
    end

    def put(language,key,value)
      blurb=@blurbs[key]
      unless blurb
        blurb={}
        @blurbs[key]=blurb
      end
      blurb[language]=value
    end
  end
end
