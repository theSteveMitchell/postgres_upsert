require 'rubygems'
require 'active_record'
require 'postgres_upsert/read_adapters/active_record_adapter'
require 'postgres_upsert/read_adapters/file_adapter'
require 'postgres_upsert/read_adapters/io_adapter'
require 'postgres_upsert/write_adapters/active_record_adapter'
require 'postgres_upsert/write_adapters/table_adapter'
require 'postgres_upsert/writer'
require 'postgres_upsert/table_writer'
require 'postgres_upsert/model_to_model_adapter'
require 'postgres_upsert/result'
require 'rails'

module PostgresUpsert
  class << self
    def write(destination, source, options = {})
      read_adapter = read_adapter(source).new(source, options)
      write_adapter = write_adapter(destination).new(destination, options)
      Writer.new(destination, write_adapter, read_adapter, options).write
    end

    def read_adapter(source)
      if [StringIO, File].include?(source.class)
        ReadAdapters::IOAdapter
      elsif [String].include?(source.class)
        ReadAdapters::FileAdapter
      elsif source < ActiveRecord::Base
        ReadAdapters::ActiveRecordAdapter
      else
        raise "Source must be a Filename string, StringIO of data, or a ActiveRecord Class."
      end
    end

    def write_adapter(destination)
      if [String].include?(destination.class)
        WriteAdapters::TableAdapter
      elsif destination <= ActiveRecord::Base
        WriteAdapters::ActiveRecordAdapter
      # elsif source < ActiveRecord::Base && destination < ActiveRecord::Base
        #ModelToModelAdapter
      else
        raise "Destination must be an ActiveRecord class or a table name string"
      end
    end
  end
end