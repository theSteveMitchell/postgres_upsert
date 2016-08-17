class CreateCounterColumnsTable < ActiveRecord::Migration
  def change
    create_table :counter_columns do |t|
      t.string :data
      t.integer :update_count, default: 0
    end
  end
end
