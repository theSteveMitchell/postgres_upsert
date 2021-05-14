module PostgresUpsert
  module ReadAdapters
    class ActiveRecordAdapter
      def initialize(source, options)
        @options = sanitize_options(options)
        @source = source
      end

      def sanitize_options(options)
        options.slice(
          :columns, :map, :unique_key
        )
      end

      def continuous_write_enabled
        false
      end

      def gets(&block)
        batch_size = 1_000
        line = ""
        conn = @source.connection.raw_connection

        conn.copy_data("COPY #{@source.table_name} TO STDOUT") do
          while (line_read = conn.get_copy_data) do
            line << line_read
          end
        end
        yield line
      end

      def columns
        @source.column_names
      end
    end
  end
end