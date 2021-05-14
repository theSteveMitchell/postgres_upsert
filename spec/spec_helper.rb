$LOAD_PATH.unshift(File.dirname(__FILE__))
require File.expand_path("../../config/environment", __FILE__)
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'fixtures/test_model'
require 'fixtures/test_model_copy'
require 'fixtures/three_column'
require 'fixtures/reserved_word_model'
require 'fixtures/composite_key_model'
require 'rspec/rails'
require 'rspec/autorun'
require 'database_cleaner/active_record'

RSpec.configure do |config|
  config.before(:example) do
    DatabaseCleaner.clean_with(:truncation)
  end
  config.expose_current_running_example_as :example
  config.infer_spec_type_from_file_location!
end
