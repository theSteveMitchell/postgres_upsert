module PostgresUpsert
  class Writer

    def initialize(klass, source, options = {})
      @klass = klass
      @options = options.reverse_merge({
        :delimiter => ",",
        :header => true,
        :unique_key => [primary_key],
        :update_only => false})
      @options[:unique_key] = Array.wrap(@options[:unique_key])
      @source = source.instance_of?(String) ? File.open(source, 'r') : source
      @columns_list = get_columns
      generate_temp_table_name
    end

    def write
      if @columns_list.empty?
        raise "Either the :columns option or :header => true are required"
      end

      csv_options = "DELIMITER '#{@options[:delimiter]}' CSV"

      copy_table = @temp_table_name
      columns_string = columns_string_for_copy
      create_temp_table

      @copy_result = database_connection.raw_connection.copy_data %{COPY #{copy_table} #{columns_string} FROM STDIN #{csv_options}} do

        while line = @source.gets do
          next if line.strip.size == 0
          database_connection.raw_connection.put_copy_data line
        end
      end

      upsert_from_temp_table
      drop_temp_table

      summarize_results
    end

  private

    def database_connection
      @klass.connection
    end

    def summarize_results
      result = PostgresUpsert::Result.new(@insert_result, @update_result, @copy_result)
      expected_rows = @options[:update_only] ? result.updated_rows : result.copied_rows
      
      if result.changed_rows != expected_rows
        raise "#{expected_rows} rows were copied, but #{result.changed_rows} were upserted to destination table.  Check to make sure your key is unique."
      end

      return result
    end

    def primary_key
      @klass.primary_key
    end

    def column_names
      @klass.column_names
    end

    def quoted_table_name
      @klass.quoted_table_name
    end

    def get_columns
      columns_list = @options[:columns] ? @options[:columns].map(&:to_s) : []
      if @options[:header]
        #if header is present, we need to strip it from io, whether we use it for the columns list or not.
        line = @source.gets
        if columns_list.empty?
          columns_list = line.strip.split(@options[:delimiter])
        end
      end
      columns_list = columns_list.map{|c| @options[:map][c.to_s] } if @options[:map]
      return columns_list
    end

    def columns_string_for_copy
      str = get_columns_string
      str.empty? ? str : "(#{str})"
    end

    def columns_string_for_select
      columns = @columns_list.clone
      columns << "created_at" if column_names.include?("created_at")
      columns << "updated_at" if column_names.include?("updated_at")
      str = get_columns_string(columns)
    end

    def columns_string_for_insert
      columns = @columns_list.clone
      columns << "created_at" if column_names.include?("created_at")
      columns << "updated_at" if column_names.include?("updated_at")
      str = get_columns_string(columns)
    end

    def select_string_for_insert
      columns = @columns_list.clone
      str = get_columns_string(columns)
      str << ",'#{DateTime.now.utc}'" if column_names.include?("created_at")
      str << ",'#{DateTime.now.utc}'" if column_names.include?("updated_at")
      str
    end

    def select_string_for_create
      columns = @columns_list.map(&:to_sym)
      @options[:unique_key].each do |key_component|
        next unless key_component
        columns << key_component.to_sym unless columns.include?(key_component.to_sym)
      end
      get_columns_string(columns)
    end

    def get_columns_string(columns = nil)
      columns ||= @columns_list
      columns.size > 0 ? "\"#{columns.join('","')}\"" : ""
    end

    def generate_temp_table_name
      @temp_table_name = "#{@table_name}_temp_#{rand(1000)}"
    end

    def upsert_from_temp_table
      insert_from_temp_table unless @options[:update_only]
    end

    def update_from_temp_table
      @update_result = database_connection.execute <<-SQL
        UPDATE #{quoted_table_name} AS d
          #{update_set_clause}
          FROM #{@temp_table_name} as t
          WHERE #{unique_key_select("t", "d")}
          AND #{unique_key_present("d")}
      SQL
    end

    def update_set_clause
      command = @columns_list.map do |col|
        "\"#{col}\" = t.\"#{col}\""
      end
      command << "\"updated_at\" = '#{DateTime.now.utc}'" if column_names.include?("updated_at")
      "SET #{command.join(',')}"
    end

    def insert_from_temp_table
      columns_string = columns_string_for_insert
      select_string = select_string_for_insert
      @insert_result = database_connection.execute <<-SQL
        INSERT INTO #{quoted_table_name} (#{columns_string})
          SELECT #{select_string}
          FROM #{@temp_table_name};
      SQL
    end

    def unique_key_select(source, dest)
      @options[:unique_key].map {|field| "#{source}.#{field} = #{dest}.#{field}"}.join(' AND ')
    end

    def unique_key_present(source)
      @options[:unique_key].map {|field| "#{source}.#{field} IS NOT NULL"}.join(' AND ')
    end

    def create_temp_table
      columns_string = select_string_for_create
      database_connection.execute <<-SQL
        SET client_min_messages=WARNING;
        DROP TABLE IF EXISTS #{@temp_table_name};

        CREATE TEMP TABLE #{@temp_table_name}
          AS SELECT #{columns_string} FROM #{quoted_table_name} WHERE 0 = 1;
      SQL
    end

    def verify_temp_has_key
      @options[:unique_key].each do |key_component|
        unless @columns_list.include?(key_component.to_s)
          raise "Expected a unique column '#{key_component}' but the source data does not include this column.  Update the :columns list or explicitly set the unique_key option.}"
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
