# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150710162236) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "composite_key_models", force: :cascade do |t|
    t.integer "comp_key_1"
    t.integer "comp_key_2"
    t.string  "data"
  end

  create_table "reserved_word_models", force: :cascade do |t|
    t.string "select", limit: 255
    t.string "group",  limit: 255
  end

  create_table "test_models", force: :cascade do |t|
    t.string   "data",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "three_columns", force: :cascade do |t|
    t.string   "data",       limit: 255
    t.string   "extra",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
