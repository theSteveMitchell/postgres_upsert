require 'rubygems'
require 'active_record'
require 'postgres_upsert/postgres_writer'
require 'postgres_upsert/postgres_dumb_writer'
require 'postgres_upsert/postgres_result'
require 'rails'

class PostgresUpsert < Rails::Railtie

  def self.write class_or_table, path_or_io, options = {}
    writer = class_or_table.is_a?(String) ?  
       PostgresDumbWriter : PostgresWriter
    writer.new(class_or_table, path_or_io, options).write
  end
end
