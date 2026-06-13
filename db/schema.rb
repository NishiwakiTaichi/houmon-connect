# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_06_13_113217) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clients", force: :cascade do |t|
    t.string "name", null: false
    t.string "kana", null: false
    t.integer "status", default: 0, null: false
    t.integer "newcomer_policy", default: 0, null: false
    t.integer "gender_restriction", default: 0, null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "recurring_visits", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "user_id", null: false
    t.integer "service_type"
    t.integer "wday"
    t.time "start_time"
    t.time "end_time"
    t.integer "frequency"
    t.string "visit_weeks"
    t.date "anchor_date"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_recurring_visits_on_client_id"
    t.index ["user_id"], name: "index_recurring_visits_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.string "name", null: false
    t.integer "role", default: 0, null: false
    t.integer "job", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kana", default: "", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "recurring_visits", "clients"
  add_foreign_key "recurring_visits", "users"
end
