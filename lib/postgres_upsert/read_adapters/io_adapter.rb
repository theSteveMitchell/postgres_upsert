module PostgresUpsert
  module ReadAdapters
    class IOAdapter
      def initialize(source, options)
        @options = sanitize_options(options)
        @source = source
      end

      def sanitize_options(options)
        options.slice(
          :delimiter, :header, :columns, :map, :unique_key
        ).reverse_merge(
          header: true,
          delimiter: ',',
        )
      end
      
      def continuous_write_enabled
        true
      end

      def gets
        @source.gets
      end

      def columns
        @columns ||= begin
          columns_list = @options[:columns] ? @options[:columns].map(&:to_s) : []
          if @options[:header]
            # if header is present, we need to strip it from io, whether we use it for the columns list or not.
            line = gets
            if columns_list.empty?
              columns_list = line.strip.split(@options[:delimiter])
            end
          end
          columns_list = columns_list.map { |c| @options[:map][c.to_s] } if @options[:map]
          columns_list
        end
      end
    end
  end
end