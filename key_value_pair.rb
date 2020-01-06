require 'tempfile'
require 'json'
require 'date'
require 'time'
require 'concurrent'
require './custom_file_system.rb'
class KeyValuePair
  include CustomThreadSafe

  MAX_FILE_SIZE = 1073741824
  MAX_KEY_LENGTH = 32
  MAX_VALUE_SIZE = 16384

  attr_accessor :file_path, :loaded_values
  #
  # initialize
  #
  # @param {String} file_path(optional)
  #
  def initialize(file_path = nil)
    @file_path = file_path || Tempfile.new("key_value_pair").path
    load_hash_values
  rescue Errno::ENOENT => e
    puts "ERROR: The File path provided seems to be incorrect."
  rescue => e
    puts "ERROR: #{e}"
  end

  #
  # get_hash_values
  #
  def get_hash_values
    @loaded_values
  end


  #
  # create
  #
  # @param {Hash} new_key_value
  #
  def create(new_key_value)
    begin
      validated_results = validate(new_key_value)
      if validated_results[:code] == 200
        CustomFileSystem.instance.open("#{@file_path}") do |f|
          file_locked = is_file_lock(f)
          return file_locked[:error_message] if file_locked

          append_values = JSON.parse(new_key_value.values.first.to_json)
          append_values[:expires_at] = Time.now + append_values["time_to_live"].to_i unless append_values["time_to_live"].nil?
          new_key_value[new_key_value.keys.first] = append_values.to_json

          f.write("#{new_key_value.keys.first},\t#{new_key_value.values.first}\n");
        end
        load_hash_values
      else
        puts "ERROR: #{validated_results[:error_message]}"
        return validated_results
      end
    rescue Errno::EACCES => e
      return {code: 500, error_message: "The File path provided doesn't have write access."}
    rescue Errno::ENOENT => e
      return {code: 500, error_message: "The File path provided seems to be incorrect."}
    rescue => e
      puts "ERROR: #{e}"
      return {code: 500, error_message: "Something went wrong!!"}
    end
  end

  #
  # delete
  #
  # @param {String} key
  #
  def delete(key)
    finded_values = find_the_element(key)
    return {code: 404, error_message: "The Entered Key Element not found."} if finded_values.nil?

    expires_at = get_expires_at(finded_values)
    return {code: 500, error_message: "The Sorry Time to Delete the data has been expired."} if expires_at && expires_at < Time.now

    @loaded_values.delete(key)
    write_back_to_file

    {code: 200}
  end

  #
  # find
  #
  # @param {String} key
  #
  def find(key)
    finded_values = find_the_element(key)
    return {code: 404, error_message: "The Entered Key Element not found."} if finded_values.nil?

    expires_at = get_expires_at(finded_values)
    return {code: 500, error_message: "The Sorry Time to Read the data has been expired."} if expires_at && expires_at < Time.now

    finded_values
  end

  #
  # validate
  #
  # @param {Hash} new_key_value
  #
  def validate(new_key_value)
    return {code: 500, error_message: "The Given Parameter is not in valid format."} unless new_key_value.is_a?(Hash)
    return {code: 500, error_message: "The File Size has been exceeded."} unless valid_file_size()
    return {code: 500, error_message: "The Given Value is not in Json Format."} unless validate_value_as_json(new_key_value.values.first)
    return {code: 500, error_message: "The Key Length has been exceeded."} unless valid_key_length(new_key_value.keys.first)
    return {code: 500, error_message: "The Size of the JSON value has been exceeded."} unless valid_value_size(new_key_value.values.first)
    return {code: 500, error_message: "The Key is already present."} if find_the_element(new_key_value.keys.first)

    {code: 200}
  end

  #
  # is_file_lock
  #
  # @param {File} file
  #
  def is_file_lock(file)
    file_locked = !(file.flock(File::LOCK_EX | File::LOCK_NB))
    return {code: 404, error_message: "The File is already being used."} if file_locked

    file_locked
  end

  private

  #
  # find_the_element
  #
  # @param {String} key
  #
  def find_the_element(key)
    @loaded_values[key.to_s]
  end

  #
  # get_expires_at
  #
  # @param {JSON} values
  #
  def get_expires_at(values)
    Time.parse((JSON.parse(values)["expires_at"])) if JSON.parse(values)["expires_at"]
  end

  #
  # load_hash_values
  #
  def load_hash_values
    values = {}
    File.foreach(@file_path) do |line|
      key, value = line.split(",\t")
      values[key] = value
    end
    @loaded_values = values
  end

  #
  # write_back_to_file
  #
  def write_back_to_file
    truncate_file if @loaded_values.empty?
    @loaded_values.each_with_index do |(key, value), index|
      CustomFileSystem.instance.open("#{@file_path}") do |f|
        f.truncate(0) if index == 0
        f.write("#{key},\t#{value}");
      end
    end
  end

  #
  # truncate_file
  #
  def truncate_file
    CustomFileSystem.instance.open("#{@file_path}") do |f|
      f.truncate(0)
    end
  end

  #
  # validate_value_as_json
  #
  # @param {Hash} value
  #
  def validate_value_as_json(value)
    begin
      raise "Invalid Format" unless value.is_a?(Hash)
      JSON.parse(value.to_json)

    rescue => e
      p "Error: The Given value is not in JSON format."
      return false
    end
  end

  #
  # valid_file_size
  #
  def valid_file_size
    File.size(@file_path) < MAX_FILE_SIZE
  end

  #
  # valid_key_length
  #
  # @param {String} key
  #
  def valid_key_length(key)
    key.length < MAX_KEY_LENGTH
  end

  #
  # valid_key_length
  #
  # @param {Hash} value
  #
  def valid_value_size(value)
    value.size < MAX_VALUE_SIZE
  end
end

