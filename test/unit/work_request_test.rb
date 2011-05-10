require  File.expand_path( File.dirname(__FILE__)) + "/../test_helper.rb"
include Rengine
class WorkRequestTest < Test::Unit::TestCase
  def test_dedup
    WorkRequest.all.each {|w|w.destroy}
    NotRelational::Repository.pause
    work="$x+=1"
    start_time=Time.now.gmtime
    created=WorkRequest.create(work,nil,:start_time=>start_time)
    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause
    WorkRequest.create(work,nil,:start_time => start_time+200)
    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause
    found=WorkRequest.all
    assert_equal(1,found.length)
    assert_equal(work,found[0].work)
    assert_equal(start_time.to_i,found[0].next_execution.to_i)
    
    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause
    WorkRequest.create(work,nil,:start_time=>start_time-200)
    NotRelational::Repository.clear_session_cache
    NotRelational::Repository.pause
    found=WorkRequest.all
    assert_equal(1,found.length)
    assert_equal(work,found[0].work)
    assert_equal(start_time.to_i-200,found[0].next_execution.to_i)
    
  end
end
