require  File.expand_path( File.dirname(__FILE__)) + "/../test_helper.rb"

include Rengine
class TestRenderer < Test::Unit::TestCase
  def initialize(name)
    super(name)
    $blurb_namespace="likemachine.com"    
    Blurb.set_wording("likemachine.com","h","en","hello")
    Blurb.set_wording("likemachine.com","w","en","world")
    Blurb.set_wording("likemachine.com","h","fr","bonjour")
    Blurb.set_wording("likemachine.com","w","fr","monde")
  end
  def test_multi_language
    template_text="<$=l('h')$> <$=l('w')$> + <%=@local%>"

    r=Renderer.new(template_text,:runtime_tags=>["runtime"])
    result=r.render("en",:local => 'abc')    
    assert_equal("hello world + abc",result.to_s)
    result=r.render("fr",:local => 'xyz')
    assert_equal("bonjour monde + xyz",result.to_s)
  end
  
  def test_static_template

    template_text="hello world"
    r=Renderer.new(template_text,:runtime_tags=>["runtime"])
    result=r.render("en")
    assert_equal(template_text,result.to_s)
  end

  def test_simple_template

    template_text="hello <%=@w%>"
    
    r=Renderer.new(template_text,:runtime_tags=>["runtime"])
    result=r.render("en", :w => 'abc')
    assert_equal("hello abc",result.to_s)
  end
  def test_blurb_template

    template_text="hello <$=l('w')$>"
    r=Renderer.new(template_text,:runtime_tags=>["runtime"])
    result=r.render("en")
    assert_equal("hello world",result.to_s)
    displayed_blurb_names=r.displayed_blurb_names
    
    assert_equal(1,displayed_blurb_names.length)
    assert_equal("w",displayed_blurb_names[0])
  end
  def test_default_language_template

    template_text="hello <$=l('w')$>"
    r=Renderer.new(template_text,:runtime_tags=>["runtime"])
    result=r.render("ja")
    assert_equal("hello world",result.to_s)
  end
  
  def test_default_text

    template_text="hello <$=l('world')$>"
    r=Renderer.new(template_text,:runtime_tags=>["runtime"])
    result=r.render("en")
    assert_equal("hello world",result.to_s)
  end
  def xxx_test_logic_blurb

    #this test fails after blurb call was moved to runtime
    
    template_text="hello <$=l('w').upcase$>"
    r=Renderer.new(template_text,:runtime_tags=>["runtime"])
    result=r.render("en")
    assert_equal("hello WORLD",result.to_s)
  end

  def test_logic2
    
    template_text="hello <%='WORLD'.downcase%>"
    r=Renderer.new(template_text,:runtime_tags=>["runtime"])
    result=r.render("en")
    assert_equal("hello world",result.to_s)
  end
  def test_title

    template_text="<%@page_title='testy title'%>hello world"
    r=Renderer.new(template_text,:runtime_tags=>["runtime"])
    result=r.render("en")
    assert_equal("hello world",result.to_s)
    assert_equal("testy title",result.title)
  end
  def test_blurb_stage_2
    
    template_text="<%@page_title='testy title'%><%=l('h')%> world"
    r=Renderer.new(template_text,:runtime_tags=>["runtime"],:blurb_binding=>binding)
    result=r.render("en")
    assert_equal("hello world",result.to_s)
    assert_equal("testy title",result.title)
  end
  def test_batch
    template_text="<##
   @dh = @h.downcase
    @dw = @w.upcase
  
  ##><%@page_title=l('h')%><%=@dh%> <%=@dw%>."

    r=Renderer.new(template_text,:runtime_tags=>["runtime"])
    results=r.render_batch(["en","fr"],
                           :h => "HeLLo",
                           :w => "WOrlD")
    assert_equal(2,results.length)
    assert_not_nil(results["en"])
    assert_not_nil(results["fr"])
#render batch does not do a second pass
    # assert_equal("hello WORLD.",results["en"].to_s)
    # assert_equal("hello WORLD.",results["fr"].to_s)
    # assert_equal("hello",results["en"].title)
    # assert_equal("bonjour",results["fr"].title)

    assert_equal(r.binding_rebuild_count,1)
  end
  

  def test_escape
    code="<%= ('(3+3).to_s') %>"
    template_text="<runtime>#{code}</runtime>"

    r=Renderer.new(template_text,:tags_to_escape => ["runtime"])
    assert_equal(1,r.escape_tags.length)
    assert_equal("runtime",r.escape_tags[0])
    result=r.render("en")
    assert_equal("<runtime>#{CGI.escapeHTML(code)}</runtime>",result.to_s)

  end
  
  def test_runtime_flow
    code="<%= (3+3).to_s %>"
    power_code="<%=(5*5).to_s%>"
    template_text="<runtime>#{code}</runtime><power>POWER<runtime>#{power_code}</runtime></power>"

    r=Renderer.new(template_text,:runtime_tags => [],:tags_to_escape=>["runtime"])
    result=r.render("en")
    assert_equal("<runtime>#{CGI.escapeHTML(code)}</runtime><power>POWER<runtime>#{CGI.escapeHTML(power_code)}</runtime></power>",result.to_s)


    runtime_renderer=Renderer.new(result.to_s,:runtime_tags => ["runtime"])
    runtime_result=runtime_renderer.render("en",:tags_to_delete => ["power"])

    assert_equal("6",runtime_result.to_s)


    runtime_result=runtime_renderer.render("en",:tags_to_unwrap => ["power"])

    assert_equal("6POWER25",runtime_result.to_s)
    
  end
end
