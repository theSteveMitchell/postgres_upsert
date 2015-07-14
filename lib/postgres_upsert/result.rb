module PostgresUpsert
  class Result
    attr_reader :inserted, :updated

    def initialize(insert_result, update_result, copy_result)
      @inserted = insert_result ? insert_result.cmd_tuples : 0
      @updated = update_result ? update_result.cmd_tuples : 0  
      @copied = copy_result ? copy_result.cmd_tuples : 0  
    end

    def changed_rows
      @inserted + @updated
    end

    def copied_rows
      @copied
    end

    def updated_rows
      @updated
    end
  end
end

