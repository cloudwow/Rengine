module Rengine
  #deprected.  just use Blurb class
  class BlurbMap
    def initialize(namespace)
      @namespace=namespace
    end

    def get(key,
            language,
            default_value)
      Blurb.get_wording(@namespace,key,language,default_value)
      
    end
  end
end
