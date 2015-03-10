$LOAD_PATH.unshift(File.dirname(__FILE__))
require File.expand_path("../../config/environment", __FILE__)
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'fixtures/test_model'
require 'fixtures/three_column'
require 'fixtures/reserved_word_model'
require 'rspec'
require 'rspec/rails'
require 'rspec/autorun'

RSpec.configure do |config|
  #config.use_transactional_fixtures = false
  config.expose_current_running_example_as :example
  config.infer_spec_type_from_file_location!
end
