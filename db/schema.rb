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

ActiveRecord::Schema[7.1].define(version: 2026_06_21_064332) do
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

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.integer "lock_type", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key", "created_at"], name: "index_good_jobs_on_concurrency_key_and_created_at"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["created_at"], name: "index_good_jobs_on_created_at"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at_only", where: "(finished_at IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_on_discarded", order: :desc, where: "((finished_at IS NOT NULL) AND (error IS NOT NULL))"
    t.index ["id"], name: "index_good_jobs_on_unfinished_or_errored", where: "((finished_at IS NULL) OR (error IS NOT NULL))"
    t.index ["job_class"], name: "index_good_jobs_on_job_class"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_for_candidate_dequeue_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_on_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at", "id"], name: "index_good_jobs_on_queue_name_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["queue_name"], name: "index_good_jobs_on_queue_name"
    t.index ["scheduled_at", "queue_name"], name: "index_good_jobs_on_scheduled_at_and_queue_name"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
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
    t.boolean "demo", default: false, null: false
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
