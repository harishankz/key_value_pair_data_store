# KeyValuePair DataStore

The KeyValue Pair DataStore used to store data in as a File

## Getting Started
 Language used is Ruby.
 
 The Maximum length of the Key is 32.
 
 The Maximum size of the value is 16 KB.
 
 The Maximum File size of the data store is 1GB.
 

### Prerequisites

gem install ruby

gem install concurrent-ruby

### Example
```

key_value_pair = KeyValuePair.new

#<KeyValuePair:0x000055fe18602e00 @file_path="/tmp/key_value_pair20200105-13464-s2vpfy", @loaded_values={}> 

response = key_value_pair.create({test_key: {"json_key": "value", "time_to_live": 10}})

{"test_key"=>"{\"json_key\":\"value\",\"time_to_live\":10,\"expires_at\":\"2020-01-05 22:26:04 +0530\"}\n"} 

response = key_value_pair.find("test_key")

{:code=>500, :error_message=>"The Sorry Time to Read the data has been expired."} 

response = key_value_pair.delete("test_key")

{:code=>500, :error_message=>"The Sorry Time to Delete the data has been expired."} 

```


## Running the tests

ruby tests/key_value_pair_test.rb 

ruby tests/custom_file_system_test.rb 

