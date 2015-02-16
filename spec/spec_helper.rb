$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'pg'
require 'postgres_upsert'
require 'rspec'
require 'rspec/autorun'

def conn
  @conn ||= PG::Connection.open(
    :host     => "localhost",
    :user     => "postgres",
    :password => "postgres",
    :port     => 5432,
    :dbname   => "ar_pg_copy_test"
  )
end

RSpec.configure do |config|
  config.before(:suite) do
    # we create a test database if it does not exist
    # I do not use database users or password for the tests, using ident authentication instead
    begin
      conn.exec_params %{
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
      conn = PG::Connection.open(
        :host     => "localhost",
        :user     => "postgres",
        :password => "postgres",
        :port     => 5432,
        :dbname   => "postgres"
      )
      conn.exec_params "DROP DATABASE IF EXISTS ar_pg_copy_test;"
      conn.exec_params "CREATE DATABASE ar_pg_copy_test;"
      retry
    end
  end

end
