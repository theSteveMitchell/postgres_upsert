module PostgresUpsert
  module WriteAdapters
    class ActiveRecordAdapter
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
        @destination.connection
      end
      
      def primary_key
        @destination.primary_key
      end

      def column_names
        @destination.column_names
      end

      def quoted_table_name
        @destination.quoted_table_name
      end
    end
  end
end