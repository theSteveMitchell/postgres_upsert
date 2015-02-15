class CreateTestTables < ActiveRecord::Migration
  def change
    create_table :test_models do |t|
      t.string :data
      t.timestamps
    end

    create_table :three_columns do |t|
      t.string :data
      t.string :extra
      t.timestamps
    end

    create_table :reserved_word_models do |t|
      t.string :select
      t.string :group
    end
  end
end
