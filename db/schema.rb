# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2015_07_10_162236) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "composite_key_models", force: :cascade do |t|
    t.integer "comp_key_1"
    t.integer "comp_key_2"
    t.string "data"
  end

  create_table "reserved_word_models", force: :cascade do |t|
    t.string "select"
    t.string "group"
  end

  create_table "test_model_copies", force: :cascade do |t|
    t.string "data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "test_models", force: :cascade do |t|
    t.string "data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "three_columns", force: :cascade do |t|
    t.string "data"
    t.string "extra"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
