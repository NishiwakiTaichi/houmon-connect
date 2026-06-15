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

ActiveRecord::Schema[7.1].define(version: 2026_06_15_144230) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activity_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "action", null: false
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.string "summary", null: false
    t.jsonb "changeset", default: {}, null: false
    t.datetime "created_at", null: false
    t.bigint "client_id"
    t.index ["client_id"], name: "index_activity_logs_on_client_id"
    t.index ["target_type", "target_id"], name: "index_activity_logs_on_target"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "client_suspensions", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "start_date"], name: "index_client_suspensions_on_client_id_and_start_date"
    t.index ["client_id"], name: "index_client_suspensions_on_client_id"
  end

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

  create_table "schedule_changes", force: :cascade do |t|
    t.bigint "recurring_visit_id", null: false
    t.bigint "registered_by_id", null: false
    t.integer "change_type", null: false
    t.date "target_date", null: false
    t.date "new_date"
    t.time "new_start_time"
    t.time "new_end_time"
    t.bigint "new_user_id"
    t.integer "reason", null: false
    t.text "reason_detail"
    t.integer "cm_contact", default: 0, null: false
    t.datetime "confirmed_at"
    t.bigint "confirmed_by_id"
    t.datetime "canceled_at"
    t.bigint "canceled_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["canceled_at"], name: "index_schedule_changes_on_canceled_at"
    t.index ["canceled_by_id"], name: "index_schedule_changes_on_canceled_by_id"
    t.index ["confirmed_at"], name: "index_schedule_changes_on_confirmed_at"
    t.index ["confirmed_by_id"], name: "index_schedule_changes_on_confirmed_by_id"
    t.index ["new_date"], name: "index_schedule_changes_on_new_date"
    t.index ["new_user_id"], name: "index_schedule_changes_on_new_user_id"
    t.index ["recurring_visit_id"], name: "index_schedule_changes_on_recurring_visit_id"
    t.index ["registered_by_id"], name: "index_schedule_changes_on_registered_by_id"
    t.index ["target_date"], name: "index_schedule_changes_on_target_date"
  end

  create_table "staff_absences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date", null: false
    t.integer "absence_type", null: false
    t.time "start_time"
    t.time "end_time"
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "date"], name: "index_staff_absences_on_user_id_and_date"
    t.index ["user_id"], name: "index_staff_absences_on_user_id"
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

  add_foreign_key "activity_logs", "clients"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "client_suspensions", "clients"
  add_foreign_key "recurring_visits", "clients"
  add_foreign_key "recurring_visits", "users"
  add_foreign_key "schedule_changes", "recurring_visits"
  add_foreign_key "schedule_changes", "users", column: "canceled_by_id"
  add_foreign_key "schedule_changes", "users", column: "confirmed_by_id"
  add_foreign_key "schedule_changes", "users", column: "new_user_id"
  add_foreign_key "schedule_changes", "users", column: "registered_by_id"
  add_foreign_key "staff_absences", "users"
end
