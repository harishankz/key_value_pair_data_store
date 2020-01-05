#require 'threads'
require 'minitest/autorun'
require 'net/http'
require 'uri'
require './custom_file_system.rb'
require './key_value_pair.rb'
class CustomFileSystemTest < MiniTest::Unit::TestCase
  include CustomThreadSafe

  def test_file_locked_state
    file_path = Tempfile.new("key_value_pair").path

    threads = []
    5.times do
      threads << Thread.start do
        200.times do |i|
          CustomFileSystem.instance.open("#{file_path}") do |f|
            file_locked = KeyValuePair.new.is_file_lock(f)
            if file_locked
              assert_equal(404, file_locked[:code])
              assert_equal("The File is already being used.", file_locked[:error_message])
            else
              assert_equal(false, file_locked)
            end
          end
        end
      end
    end

    threads.each { |t| t.join }
  end
end
