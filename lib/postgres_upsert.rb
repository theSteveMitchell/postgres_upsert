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

    def adapter(destination, source)
      if [String, StringIO].include?(source.class) && destination.is_a?(String)
        TableWriter
      elsif [String, StringIO].include?(source.class) && destination < ActiveRecord::Base
        Writer
      elsif source < ActiveRecord::Base && destination < ActiveRecord::Base
        ModelToModelAdapter
      else
        raise ArgumentError "Source must be a Filename string, StringIO of data, or a ActiveRecord Class. Desination must be an ActiveRecord class or a table_name string."
      end
    end
  end
end