$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'fixtures/test_model'
require 'fixtures/three_column'
require 'fixtures/reserved_word_model'
require 'rspec'
require 'rspec/autorun'

RSpec.configure do |config|
  #config.use_transactional_fixtures = false
end
