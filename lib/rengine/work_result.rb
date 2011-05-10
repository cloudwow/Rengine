module Rengine
  class WorkResult
    attr_reader :work_request
    attr_reader :error
    attr_reader :output
    def initialize(work_request,result)
      if result.is_a? Exception
        @error=result
      else
        @output=result
      end
      @work_request=work_request
    end
  end
end
