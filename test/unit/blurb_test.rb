require  File.expand_path( File.dirname(__FILE__)) + "/../test_helper.rb"
include Rengine
class BlurbTest < Test::Unit::TestCase

  def BlurbTest.set_up
    Blurb.all.each{|b|b.destroy}
    Nanikore::TimedCache.clear_all
  end

  def test_blurb_get()
    BlurbTest.set_up
    blurb=Blurb.new()
    blurb.name='test1'
    blurb.namespace='xxx'
    blurb.save
  
    found=Blurb.get('xxx','test1')
    assert_not_nil(found)
    assert_equal(blurb.id,found.id)
  end

  def test_escape_html

        BlurbTest.set_up

    blurb1=Blurb.new()
    blurb1.name='blurb1'
    blurb1.namespace=Blurb.environment_namespace
    blurb1.save
    blurb1.set_wording('en','ABC_#{x}')

    NotRelational::Repository.pause
    result=Blurb.l("blurb1",:x=>"<script>",:html_escape=>true)
    expected="ABC_"+CGI.escapeHTML("<script>")
    assert_equal expected,result
    
  end
  def test_get_wording()
#    BlurbTest.set_up
    blurb1=Blurb.new()
    blurb1.name='blurb1'
    blurb1.namespace='xxx'
    blurb1.save
    blurb2=Blurb.new()
    blurb2.name='blurb2'
    blurb2.namespace='xxx'
    blurb2.save
    NotRelational::Repository.pause
    
    blurb1.set_wording('en','duh1en')
    
    blurb1.set_wording('ja','duh1ja')
    
    Blurb.set_wording('xxx','blurb2','en','duh2en')
    
    Blurb.set_wording('xxx','blurb2','ja','duh2ja')
    NotRelational::Repository.pause
    
    assert_equal('duh1ja',Blurb.get_wording('xxx','blurb1','ja'))
    assert_equal('duh1ja',blurb1.get_wording('ja'))
    
    assert_equal('duh1en',Blurb.get_wording('xxx','blurb1','en'))
    assert_equal('duh1en',blurb1.get_wording('en'))
    
    assert_equal('duh1en',Blurb.get_wording('xxx','blurb1','fr'))
    assert_equal('duh1en',blurb1.get_wording('fr'))
    
    assert_equal('duh2ja',Blurb.get_wording('xxx','blurb2','ja'))
    assert_equal('duh2ja',blurb2.get_wording('ja'))
    
    assert_equal('duh2en',Blurb.get_wording('xxx','blurb2','en'))
    assert_equal('duh2en',blurb2.get_wording('en'))
    
    assert_equal('duh2en',Blurb.get_wording('xxx','blurb2','fr'))
    assert_equal('duh2en',blurb2.get_wording('fr'))
    NotRelational::Repository.pause
    
    Nanikore::TimedCache.clear_all
    assert_equal('duh1ja',Blurb.get_wording('xxx','blurb1','ja'))
    assert_equal('duh1ja',blurb1.get_wording('ja'))
    
    assert_equal('duh1en',Blurb.get_wording('xxx','blurb1','en'))
    assert_equal('duh1en',blurb1.get_wording('en'))
    
    assert_equal('duh1en',Blurb.get_wording('xxx','blurb1','fr'))
    assert_equal('duh1en',blurb1.get_wording('fr'))
    
    assert_equal('duh2ja',Blurb.get_wording('xxx','blurb2','ja'))
    assert_equal('duh2ja',blurb2.get_wording('ja'))
    
    assert_equal('duh2en',Blurb.get_wording('xxx','blurb2','en'))
    assert_equal('duh2en',blurb2.get_wording('en'))
    
    assert_equal('duh2en',Blurb.get_wording('xxx','blurb2','fr'))
    assert_equal('duh2en',blurb2.get_wording('fr'))
    
    blurb1.set_wording('ja','duh1ja_b')
    NotRelational::Repository.pause
    

    Nanikore::TimedCache.clear_all

    assert_equal('duh1ja_b',Blurb.get_wording('xxx','blurb1','ja'))
    assert_equal('duh1ja_b',blurb1.get_wording('ja'))
    
  end
  
end
