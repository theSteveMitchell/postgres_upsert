module PostgresUpsert
  class Writer

    def initialize(klass, destination, source, options = {})
      @klass = klass
      @destination = destination
      @source = source
      @options = options.reverse_merge({
        delimiter: ',',
        header: true,
        unique_key: [primary_key],
        update_only: false
      })
      @source = source
      @options[:unique_key] = Array.wrap(@options[:unique_key])

    end

    def write
      validate_options

      
      create_temp_table

      if @source.continuous_write_enabled
        write_continuous
      else
        write_batched
      end

      upsert_from_temp_table
      drop_temp_table

      summarize_results
    end

  private

    def write_continuous
      csv_options = "DELIMITER '#{@options[:delimiter]}' CSV"
      @copy_result = database_connection.raw_connection.copy_data %{COPY #{@temp_table_name} #{columns_string_for_copy} FROM STDIN #{csv_options}} do
        while (line = @source.gets)
          next if line.strip.empty?

          database_connection.raw_connection.put_copy_data line
        end
      end
    end

    def write_batched
      @source.gets do |line|
        @copy_result = database_connection.raw_connection.copy_data %{COPY #{@temp_table_name} #{columns_string_for_copy} FROM STDIN} do
          database_connection.raw_connection.put_copy_data line
        end
      end
    end

    def database_connection
      @destination.database_connection
    end

    def summarize_results
      result = PostgresUpsert::Result.new(@insert_result, @update_result, @copy_result)
      expected_rows = @options[:update_only] ? result.updated_rows : result.copied_rows

      if result.changed_rows != expected_rows
        raise "#{expected_rows} rows were copied, but #{result.changed_rows} were upserted to destination table.  Check to make sure your key is unique."
      end

      result
    end

    def primary_key
      @destination.primary_key
    end

    def destination_columns
      @destination.column_names
    end

    def quoted_table_name
      @destination.quoted_table_name
    end

    def source_columns
      @source.columns
    end

    def columns_string_for_copy
      str = get_columns_string
      str.empty? ? str : "(#{str})"
    end

    def columns_string_for_select
      columns = source_columns.clone
      columns << 'created_at' if inject_create_timestamp?
      columns << 'updated_at' if inject_update_timestamp?
      get_columns_string(columns)
    end

    def columns_string_for_insert
      columns = source_columns.clone
      columns << 'created_at' if inject_create_timestamp?
      columns << 'updated_at' if inject_update_timestamp?
      get_columns_string(columns)
    end

    def select_string_for_insert
      columns = source_columns.clone
      str = get_columns_string(columns)
      str << ",'#{DateTime.now.utc}'" if inject_create_timestamp?
      str << ",'#{DateTime.now.utc}'" if inject_update_timestamp?
      str
    end

    def inject_create_timestamp?
      destination_columns.include?('created_at') &&  !source_columns.include?('created_at')
    end

    def inject_update_timestamp?
      destination_columns.include?('updated_at') &&  !source_columns.include?('updated_at')
    end

    def select_string_for_create
      columns = source_columns.map(&:to_sym)
      @options[:unique_key].each do |key_component|
        columns << key_component.to_sym unless columns.include?(key_component.to_sym)
      end
      get_columns_string(columns)
    end

    def get_columns_string(columns = nil)
      columns ||= source_columns
      !columns.empty? ? "\"#{columns.join('","')}\"" : ''
    end

    def generate_temp_table_name
      @temp_table_name ||= "#{@table_name}_temp_#{rand(1000)}"
    end

    def upsert_from_temp_table
      update_from_temp_table
      insert_from_temp_table unless @options[:update_only]
    end

    def update_from_temp_table
      @update_result = database_connection.execute <<-SQL
        UPDATE #{quoted_table_name} AS d
          #{update_set_clause}
          FROM #{@temp_table_name} as t
          WHERE #{unique_key_select('t', 'd')}
          AND #{unique_key_present('d')}
      SQL
    end

    def update_set_clause
      command = source_columns.map do |col|
        "\"#{col}\" = t.\"#{col}\""
      end
      unless source_columns.include?('updated_at')
        command << "\"updated_at\" = '#{DateTime.now.utc}'" if destination_columns.include?('updated_at')
      end
        "SET #{command.join(',')}"
    end

    def insert_from_temp_table
      columns_string = columns_string_for_insert
      select_string = select_string_for_insert
      @insert_result = database_connection.execute <<-SQL
        INSERT INTO #{quoted_table_name} (#{columns_string})
          SELECT #{select_string}
          FROM #{@temp_table_name} as t
          WHERE NOT EXISTS
            (SELECT 1
                  FROM #{quoted_table_name} as d
                  WHERE #{unique_key_select('t', 'd')});
      SQL
    end

    def unique_key_select(source, dest)
      @options[:unique_key].map { |field| "#{source}.#{field} = #{dest}.#{field}" }.join(' AND ')
    end

    def unique_key_present(source)
      @options[:unique_key].map { |field| "#{source}.#{field} IS NOT NULL" }.join(' AND ')
    end

    def create_temp_table
      generate_temp_table_name
      database_connection.execute <<-SQL
        SET client_min_messages=WARNING;
        DROP TABLE IF EXISTS #{@temp_table_name};

        CREATE TEMP TABLE #{@temp_table_name}
          AS SELECT #{select_string_for_create} FROM #{quoted_table_name} WHERE 0 = 1;
      SQL
    end

    def validate_options
      if source_columns.empty?
        raise 'Either the :columns option or :header => true are required'
      end

      @options[:unique_key].each do |key_component|
        unless source_columns.include?(key_component.to_s)
          raise "Expected column '#{key_component}' was not found in source"
        end
      end
    end

    def drop_temp_table
      database_connection.execute <<-SQL
        DROP TABLE #{@temp_table_name}
      SQL
    end
  end
end
