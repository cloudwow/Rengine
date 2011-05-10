module Rengine
  class TranslationTool
    def self.tools_for_all_blurbs(blurbs,language=nil)
      unless @translation_tool_renderer
        
        path=File.dirname(__FILE__) +"/views/translation_tool.html.erb"
        text=File.open(path).read
        @translation_tool_renderer=Renderer.new(text)
      end
      @translation_tool_renderer.render(language || $language,
                                        :language=>language || $language,
                                        :blurbs=>blurbs,
                                        :translation_form_url =>"/blurb/translate").to_s
      
    end
    
    def self.tool_html_for_blurb(blurb_name,options={})
      unless @single_translation_tool_renderer
        path=File.dirname(__FILE__) +"/views/single_translation_tool.html.erb"
        text=File.open(path).read
        @single_translation_tool_renderer=Renderer.new(text)
      end

      wording=options[:wording] || Blurb.get_wording(blurb_name)
      @single_translation_tool_renderer.render(options[:language] || $language,
                                               :language=>options[:language] || $language,
                                               :blurb=>blurb_name,
                                               :wording => wording,
                                               :translation_action =>"/blurb/translate").to_s
      
    end
  end
end
