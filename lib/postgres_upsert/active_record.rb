module ActiveRecord
  class Base
    # Copy data to a file passed as a string (the file path) or to lines that are passed to a block

    # Copy data from a CSV that can be passed as a string (the file path) or as an IO object.
    # * You can change the default delimiter passing delimiter: '' in the options hash
    # * You can map fields from the file to different fields in the table using a map in the options hash
    # * For further details on usage take a look at the README.md
    def self.pg_upsert path_or_io, options = {}
      PostgresUpsert::Writer.new(table_name, path_or_io, options).write
    end
  end
end
