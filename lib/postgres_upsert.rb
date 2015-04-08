require 'rubygems'
require 'active_record'
require 'postgres_upsert/writer'
require 'postgres_upsert/table_writer'
require 'postgres_upsert/result'
require 'rails'

module PostgresUpsert

  class << self
    def write class_or_table, path_or_io, options = {}
      writer = class_or_table.is_a?(String) ?  
         TableWriter : Writer
      writer.new(class_or_table, path_or_io, options).write
    end
  end
end
