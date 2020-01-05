#require 'threads'
require 'minitest/autorun'
require 'net/http'
require 'uri'
require './custom_file_system.rb'
require './key_value_pair.rb'
class CustomFileSystemTest < MiniTest::Unit::TestCase
  include CustomThreadSafe

  def test_file_locked_state
    key_value_pair = KeyValuePair.new
    file_path = key_value_pair.file_path

    threads = []
    5.times do
      threads << Thread.start do
        5.times do |i|
          CustomFileSystem.instance.open("#{file_path}") do |f|
            sleep(3)
            file_locked = key_value_pair.is_file_lock(f)
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
