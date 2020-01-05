require 'minitest/autorun'
require 'net/http'
require 'uri'
require './custom_file_system.rb'
require './key_value_pair.rb'
class KeyValuePairTest < MiniTest::Unit::TestCase
  include CustomThreadSafe

  def setup
    @key_value_pair = KeyValuePair.new
  end

  #
  # test_create_the_element
  #
  def test_create_the_element
    @key_value_pair.create({test_create: {"json_key": "value"}})
    found_values = @key_value_pair.find("test_create")
    assert_equal found_values.nil?, false
  end

  #
  # test_find_the_element_expiry
  #
  def test_find_the_element_expiry
    @key_value_pair.create({test_find: {"json_key": "value", "time_to_live": 10}})
    found_values = @key_value_pair.find("test_find")
    assert_equal false, found_values.nil?

    sleep 10

    response = @key_value_pair.find("test_find")
    assert_equal 500, response[:code]
    assert_equal "The Sorry Time to Read the data has been expired.", response[:error_message]
  end

  #
  # test_delete_the_key
  #
  def test_delete_the_key
    @key_value_pair.create({test_delete: {"json_key": "value", "time_to_live": 10}})

    found_values = @key_value_pair.find("test_delete")
    assert_equal false, found_values.nil?

    response = @key_value_pair.delete("test_delete")
    assert_equal 200, response[:code]
  end

  #
  # test_delete_key_with_expiry
  #
  def test_delete_key_with_expiry
    @key_value_pair.create({test_delete: {"json_key": "value", "time_to_live": 10}})

    sleep 10

    response = @key_value_pair.delete("test_delete")

    assert_equal 500, response[:code]
    assert_equal "The Sorry Time to Delete the data has been expired.", response[:error_message]
  end

  #
  # test_create_duplicate_key
  #
  def test_create_duplicate_key
    @key_value_pair.create({duplicate_key: {"json_key": "value", "time_to_live": 10}})

    response =  @key_value_pair.create({duplicate_key: {"json_key": "value", "time_to_live": 10}})

    assert_equal 500, response[:code]
    assert_equal "The Key is already present.", response[:error_message]
  end

  #
  # test_key_length_error
  #
  def test_key_length_error
    response = @key_value_pair.create({'The Length of the key will exceed more than 32 characters': {"json_key": "value", "time_to_live": 10}})

    assert_equal 500, response[:code]
    assert_equal "The Key Length has been exceeded.", response[:error_message]
  end

  #
  # test_the_given_value_is_json
  #
  def test_the_given_value_is_json
    response = @key_value_pair.create({test_find: "a"})

    assert_equal 500, response[:code]
    assert_equal "The Given Value is not in Json Format.", response[:error_message]
  end
end
