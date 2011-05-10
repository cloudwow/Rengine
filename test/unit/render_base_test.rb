require  File.expand_path( File.dirname(__FILE__)) + "/../test_helper.rb"
include Rengine
class TestRenderer < Test::Unit::TestCase
  def initialize(name)
    super(name)
    @blurbs=MemoryBlurbMap.new
    @blurbs.put("en","h","hello")
    @blurbs.put("en","w","world")
    @blurbs.put("fr","h","bonjour")
    @blurbs.put("fr","w","monde")

    @languages=["en","fr"]
  end
  def setup
    
    @storage=NotRelational::MemoryStorage.new
    
    @render_base=RenderBase.new(
                                File.dirname(__FILE__)+"/views",
                                @languages,
                                "gc",
                                @storage,
                                "testy_bucket",
                                :blurb_map => @blurbs)
  end

  def test_static_template
    rb=setup
    result=rb.render(:template_name=>"aa/static_page",:language => "en",:key => "key1")
    assert_equal("this is the static template\n",result.html)
    
  end

  def test_localized_template
    # rb=setup

    # result=rb.render(:template_name => "aa/localized",:language => "en",:key => "key1")
    # assert_equal("hello world.\n",result.to_s)
    # assert_equal("hello",result.title)
    # result=rb.render(:template_name=>"aa/localized",:language => "fr",:key => "key1")
    # assert_equal("bonjour monde.\n",result.to_s)
    # assert_equal("bonjour",result.title)
    
  end

  def test_args
    rb=setup
    result=rb.render("aa/args","en","key1",:w => "whirled")
    assert_equal("whirled.\n",result.to_s)
    result=rb.render("aa/args","fr","key1",:w => "whirled2")
    assert_equal("whirled2.\n",result.to_s)
  end

  def test_key
    rb=setup
    result=rb.render(:template_name =>  "aa/key",
                     :language => "en",
                     :render_args => {
                       :arg1 => "111",
                       :arg2=> "222"})
    assert_equal("111/222",result.key)
  end

  def test_cache
    rb=setup
    result=rb.render(
                     :template_name => "aa/static_page",
                     :key=>"key1",
                     :language=>"en")
    assert_equal("this is the static template\n",result.html)
    cached=@storage.get("testy_bucket","key1")
    assert_not_nil(cached)
    result=rb.render(:template_name => "aa/static_page",:language => "fr",:key => "key1")
    assert_equal("this is the static template\n",result.html)
    cached=@storage.get("testy_bucket","fr/key1")
    assert_not_nil(cached)

  end
end
