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

ActiveRecord::Schema.define(version: 20171003090252) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "averages", force: :cascade do |t|
    t.bigint "report_id"
    t.datetime "from"
    t.datetime "to"
    t.integer "avgresponse"
    t.integer "totalup"
    t.integer "totaldown"
    t.integer "totalunknown"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["report_id"], name: "index_averages_on_report_id"
  end

  create_table "crons", force: :cascade do |t|
    t.string "name"
    t.bigint "job_id"
    t.integer "hour", limit: 2
    t.integer "day_of_week", limit: 2
    t.integer "day_of_month", limit: 2
    t.integer "month", limit: 2
    t.string "status", limit: 10, default: "ok"
    t.datetime "last_execution"
    t.datetime "next_execution"
    t.string "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_crons_on_job_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_customers_on_deleted_at"
  end

  create_table "global_reports", force: :cascade do |t|
    t.string "resolution", null: false
    t.string "period", null: false
    t.date "start_date", null: false
    t.string "status", null: false
    t.datetime "from", null: false
    t.datetime "to", null: false
    t.json "data"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_global_reports_on_deleted_at"
    t.index ["start_date", "period", "resolution", "deleted_at"], name: "unique_global_report_index", unique: true
  end

  create_table "global_settings", force: :cascade do |t|
    t.string "name", null: false
    t.json "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_global_settings_on_name", unique: true
  end

  create_table "histories", force: :cascade do |t|
    t.string "text"
    t.string "level", limit: 5, default: "info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", limit: 10, default: "message"
    t.bigint "cron_id"
    t.integer "history_id"
    t.index ["cron_id"], name: "index_histories_on_cron_id"
  end

  create_table "jobs", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "source"
    t.text "out"
    t.index ["name"], name: "index_jobs_on_name", unique: true
  end

  create_table "outages", force: :cascade do |t|
    t.datetime "timefrom"
    t.datetime "timeto"
    t.string "status", limit: 10
    t.bigint "report_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["report_id"], name: "index_outages_on_report_id"
  end

  create_table "performances", force: :cascade do |t|
    t.datetime "starttime"
    t.integer "avgresponse"
    t.integer "uptime"
    t.integer "downtime"
    t.integer "unmonitored"
    t.bigint "report_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["report_id"], name: "index_performances_on_report_id"
  end

  create_table "reports", force: :cascade do |t|
    t.string "status"
    t.json "data"
    t.bigint "vpc_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "uptime"
    t.integer "downtime"
    t.integer "unknown"
    t.integer "adjusted_downtime"
    t.integer "avg_response"
    t.bigint "global_report_id"
    t.index ["deleted_at"], name: "index_reports_on_deleted_at"
    t.index ["global_report_id"], name: "index_reports_on_global_report_id"
    t.index ["vpc_id"], name: "index_reports_on_vpc_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vpcs", force: :cascade do |t|
    t.string "hostname"
    t.datetime "created"
    t.datetime "lasterrortime"
    t.integer "lastresponsetime"
    t.datetime "lasttesttime"
    t.string "name"
    t.integer "resolution"
    t.string "status"
    t.json "data"
    t.bigint "customer_id"
    t.string "check_type"
    t.string "timezone", default: "UTC"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_vpcs_on_customer_id"
    t.index ["deleted_at"], name: "index_vpcs_on_deleted_at"
  end

  add_foreign_key "averages", "reports"
  add_foreign_key "crons", "jobs"
  add_foreign_key "outages", "reports"
  add_foreign_key "performances", "reports"
  add_foreign_key "reports", "global_reports"
  add_foreign_key "reports", "vpcs"
  add_foreign_key "vpcs", "customers"
end
