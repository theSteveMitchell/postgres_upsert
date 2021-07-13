require 'csv'

module PostgresUpsert
  class ModelToModelAdapter
    def initialize(destination_model, source_model, options = {})
      @destination_model = destination_model
      @source_model = source_model
      @options = options
    end

    def write
        source_table = @source_model.table_name
        source_conn = @source_model.connection.raw_connection

        to_stdout_sql = "COPY #{source_table} TO STDOUT"
      
        csv_string = CSV.generate do |csv|
          csv << @source_model.column_names # CSV header row
          source_conn.copy_data(to_stdout_sql) do
            while (line = source_conn.get_copy_data) do
              csv << line.split("\t")
            end
          end
        end
        io = StringIO.new(csv_string)
        Writer.new(@destination_model, io, @options).write
    end
  
  private

    def get_columns
      # columns_list = @options[:columns] 
      # columns_list ||= 
      @source.column_names
    end
  end
end