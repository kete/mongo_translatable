# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110112023516) do

  create_table "comments", :force => true do |t|
    t.string   "subject"
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", :force => true do |t|
    t.string   "label",           :null => false
    t.string   "value"
    t.string   "locale"
    t.string   "original_locale"
    t.string   "description"
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "not_swapped_in_records", :force => true do |t|
    t.string   "name",            :null => false
    t.string   "locale"
    t.string   "original_locale"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "people", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "recipes", :force => true do |t|
    t.string   "name",            :null => false
    t.string   "locale",          :null => false
    t.string   "original_locale", :null => false
    t.text     "ingredients",     :null => false
    t.text     "steps",           :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
