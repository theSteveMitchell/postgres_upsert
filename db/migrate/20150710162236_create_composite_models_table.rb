class CreateCompositeModelsTable < ActiveRecord::Migration
  def change
    create_table :composite_key_models do |t|
      t.integer :comp_key_1
      t.integer :comp_key_2
      t.string :data
    end
  end
end
