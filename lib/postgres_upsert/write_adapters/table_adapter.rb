module PostgresUpsert
  module WriteAdapters
    class TableAdapter
      def initialize(destination, options)
        @destination = destination
        @options = sanitize_options(options)
      end

      def sanitize_options(options)
        options.slice(
          :delimiter, :unique_key
        ).reverse_merge(
          delimiter: ',',
          unique_key: [primary_key],
        )
      end

      def database_connection
        ActiveRecord::Base.connection
      end

      def primary_key
        @primary_key ||= begin
          query = <<-SELECT_KEY
            SELECT
              pg_attribute.attname,
              format_type(pg_attribute.atttypid, pg_attribute.atttypmod)
            FROM pg_index, pg_class, pg_attribute
            WHERE
              pg_class.oid = '#{@destination}'::regclass AND
              indrelid = pg_class.oid AND
              pg_attribute.attrelid = pg_class.oid AND
              pg_attribute.attnum = any(pg_index.indkey)
            AND indisprimary
          SELECT_KEY
  
          pg_result = ActiveRecord::Base.connection.execute query
          pg_result.each { |row| return row['attname'] }
        end
      end

      def column_names
        @column_names ||= begin
          query = "SELECT * FROM information_schema.columns WHERE TABLE_NAME = '#{@destination}'"
          pg_result = ActiveRecord::Base.connection.execute query
          pg_result.map { |row| row['column_name'] }
        end
      end
  
      def quoted_table_name
        @quoted_table_name ||= database_connection.quote_table_name(@destination)
      end

    end
  end
end