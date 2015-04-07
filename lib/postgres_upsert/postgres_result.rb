class PostgresResult
  attr_reader :inserted, :updated

  def initialize(insert_result, update_result)
    @inserted = insert_result ? insert_result.cmd_tuples : 0
    @updated = update_result ? update_result.cmd_tuples : 0  
  end
end

