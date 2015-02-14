class CreateTestTables < ActiveRecord::Migration
  def change
    create_table :test_models do |t|
      t.string :data
      t.timestamps
    end

    create_table :three_column do |t|
      t.string :data
      t.string :extra_data
      t.timestamps
    end

    create_table :reserved_word_models do |t|
      t.string :select
      t.string :group
    end
  end
end
