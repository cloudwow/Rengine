module Rengine
  module UriUtil
    def escape_path_element(txt)
      URI.escape( value, Regexp.new("[^-_!~*'()a-zA-Z\\d]")  )
    end
  end
end
