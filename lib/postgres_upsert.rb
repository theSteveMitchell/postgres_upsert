require 'rubygems'
require 'active_record'
require 'postgres_upsert/writer'
require 'postgres_upsert/table_writer'
require 'postgres_upsert/model_to_model_adapter'
require 'postgres_upsert/result'
require 'rails'

module PostgresUpsert
  class << self
    def write(destination, source, options = {})
      adapter = adapter(destination, source)

      adapter.new(destination, source, options).write
    end

    def adapter(source, destination)
      if source <= ActiveRecord::Base && destination <= ActiveRecord::Base
        ModelToModelAdapter
      elsif destination <= ActiveRecord::Base
        # FileToModelAdapter
        Writer
      else
        TableWriter
      end
    end
  end
end