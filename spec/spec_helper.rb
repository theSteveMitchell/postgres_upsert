$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'fixtures/test_model'
require 'fixtures/three_column'
require 'fixtures/reserved_word_model'
require 'rspec'
require 'rspec/autorun'

RSpec.configure do |config|
  config.before(:suite) do
    # we create a test database if it does not exist
    # I do not use database users or password for the tests, using ident authentication instead
    begin
      ActiveRecord::Base.establish_connection(
        :adapter  => "postgresql",
        :host     => "localhost",
        :port     => 5432,
        :database => "ar_pg_copy_test"
      )
      ActiveRecord::Base.connection.execute %{
        SET client_min_messages TO warning;
        DROP TABLE IF EXISTS test_models;
        DROP TABLE IF EXISTS three_columns;
        DROP TABLE IF EXISTS reserved_word_models;
        CREATE TABLE test_models (id serial PRIMARY KEY, data text, created_at timestamp with time zone, updated_at timestamp with time zone );
        CREATE TABLE three_columns (id serial PRIMARY KEY, data text, extra text, created_at timestamp with time zone, updated_at timestamp with time zone );
        CREATE TABLE reserved_word_models (id serial PRIMARY KEY, "select" text, "group" text);
      }
    rescue Exception => e
      puts "Exception: #{e}"
      ActiveRecord::Base.establish_connection(
        :adapter  => "postgresql",
        :host     => "localhost",
        :port     => 5432,
        :database => "postgres"
      )
      ActiveRecord::Base.connection.execute "DROP DATABASE IF EXISTS ar_pg_copy_test"
      ActiveRecord::Base.connection.execute "CREATE DATABASE ar_pg_copy_test;"
      retry
    end
  end

end
