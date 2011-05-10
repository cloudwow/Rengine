module Rengine
  module UriUtil
    def escape_path_element(value)
      URI.escape( value, Regexp.new("[^-_!~*'()a-zA-Z\\d]")  )
    end
  end
end
