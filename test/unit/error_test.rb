require  File.expand_path( File.dirname(__FILE__)) + "/../test_helper.rb"
include Rengine

class UserTest < Test::Unit::TestCase

  def test_create_from_hash
    created=Rengine::Error.create(:message=>"message1",:host=>"host1",:backtrace => "backtrace1",:environment=> "env1")
    assert_equal("message1",created.message)
    assert_equal("host1",created.host)
    assert_equal("backtrace1",created.backtrace)
    assert_equal("env1",created.environment)
      assert_not_nil(created.creation_time)

  end

  def test_create_from_exception

          ENV["RAILS_ENV"]="prod1"
      ENV["HOSTNAME"]="host1"
    begin
      raise "message2"
    rescue => e
      created=Rengine::Error.create(e)

      assert( created.message.index("message2"))
      assert_equal("prod1",created.environment)
      assert_equal("host1",created.host)
      assert(created.backtrace.index("test_create_from_exception"))
      assert_not_nil(created.creation_time)

    end
    
  end

end
