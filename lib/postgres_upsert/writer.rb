module PostgresUpsert

  class Writer

    def initialize(table_name, source, options = {})
      @table_name = table_name
      @options = options.reverse_merge({
        :delimiter => ",", 
        :format => :csv, 
        :header => true, 
        :key_column => primary_key,
        :update_only => false})
      @source = source.instance_of?(String) ? File.open(source, 'r') : source
      @columns_list = get_columns
      generate_temp_table_name
    end

    def write
      if @columns_list.empty? 
        raise "Either the :columns option or :header => true are required"
      end

      csv_options = @options[:format] == :binary ? "BINARY" : "DELIMITER '#{@options[:delimiter]}' CSV"

      copy_table = @temp_table_name
      destination_table = quoted_table_name

      columns_string = columns_string_for_copy
      create_temp_table

      ActiveRecord::Base.connection.raw_connection.copy_data %{COPY #{copy_table} #{columns_string} FROM STDIN #{csv_options}} do

        while line = read_input_line do
          next if line.strip.size == 0
          ActiveRecord::Base.connection.raw_connection.put_copy_data line
        end
      end

      if destination_table
        upsert_from_temp_table
        drop_temp_table
      end
    end

  private

    def primary_key
      @primary_key ||= begin
        query = <<-sql
          SELECT
            pg_attribute.attname,
            format_type(pg_attribute.atttypid, pg_attribute.atttypmod)
          FROM pg_index, pg_class, pg_attribute
          WHERE
            pg_class.oid = '#{@table_name}'::regclass AND
            indrelid = pg_class.oid AND
            pg_attribute.attrelid = pg_class.oid AND
            pg_attribute.attnum = any(pg_index.indkey)
          AND indisprimary
        sql

        pg_result = ActiveRecord::Base.connection.execute query
        pg_result.each{ |row| return row['attname'] }
      end
    end

    def column_names
      @column_names ||= begin
        query = "SELECT * FROM information_schema.columns WHERE TABLE_NAME = '#{@table_name}'"
        pg_result = ActiveRecord::Base.connection.execute query
        pg_result.map{ |row| row['column_name'] }
      end
    end

    def get_columns
      columns_list = @options[:columns] || []
      if @options[:format] != :binary && @options[:header]
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
      columns << @options[:key_column].to_sym unless columns.include?(@options[:key_column].to_sym)
      get_columns_string(columns)
    end

    def get_columns_string(columns = nil)
      columns ||= @columns_list
      columns.size > 0 ? "\"#{columns.join('","')}\"" : ""
    end

    def quoted_table_name
      @quoted_table_name ||= ActiveRecord::Base.connection.quote_table_name(@table_name)
    end

    def generate_temp_table_name
      @temp_table_name = "#{@table_name}_temp_#{rand(1000)}"
    end

    def read_input_line
      if @options[:format] == :binary
        begin
          return @source.readpartial(10240)
        rescue EOFError
        end
      else
        line = @source.gets
        return line
      end
    end

    def upsert_from_temp_table
      update_from_temp_table
      insert_from_temp_table unless @options[:update_only]
    end

    def update_from_temp_table
      ActiveRecord::Base.connection.execute <<-SQL
        UPDATE #{quoted_table_name} AS d
          #{update_set_clause}
          FROM #{@temp_table_name} as t
          WHERE t.#{@options[:key_column]} = d.#{@options[:key_column]}
          AND d.#{@options[:key_column]} IS NOT NULL;
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
      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO #{quoted_table_name} (#{columns_string})
          SELECT #{select_string}
          FROM #{@temp_table_name} as t
          WHERE NOT EXISTS 
            (SELECT 1 
                  FROM #{quoted_table_name} as d 
                  WHERE d.#{@options[:key_column]} = t.#{@options[:key_column]})
          AND t.#{@options[:key_column]} IS NOT NULL;
      SQL
    end

    def create_temp_table
      columns_string = select_string_for_create
      ActiveRecord::Base.connection.execute <<-SQL
        SET client_min_messages=WARNING;
        DROP TABLE IF EXISTS #{@temp_table_name};

        CREATE TEMP TABLE #{@temp_table_name} 
          AS SELECT #{columns_string} FROM #{quoted_table_name} WHERE 0 = 1;
      SQL
    end

    def drop_temp_table
      ActiveRecord::Base.connection.execute <<-SQL
        DROP TABLE #{@temp_table_name} 
      SQL
    end
  end


end
