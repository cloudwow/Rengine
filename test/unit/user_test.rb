require  File.expand_path( File.dirname(__FILE__)) + "/../test_helper.rb"
include Rengine

class UserTest < Test::Unit::TestCase
  class AppUser  < NotRelational::DomainModel
    include RengineUser
    property :myprop,:string
  end
  def test_create
    u=AppUser.create("john","123456")
    u.save
    found=AppUser.find("john")
    assert_not_nil(found)
    assert_equal("john",found.login)
    assert(found.authenticated?("123456"))
    
  end

  def test_find_wrong_case
    u=AppUser.create("joHN","123456")
    u.save
    found=AppUser.find("JOhn")
    assert_not_nil(found)
    assert_equal("john",found.login)
    assert(found.authenticated?("123456"))
    
  end
  def test_mixed_props
    u=AppUser.create("john","123456",:myprop=>"hello",:email=>"john@yahoo.com")
    u.save
    found=AppUser.find("john")
    assert_not_nil(found)
    assert_equal("hello",found.myprop)
    assert_equal(found.email,"john@yahoo.com")
  end
  
end
