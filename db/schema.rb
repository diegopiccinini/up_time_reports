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

ActiveRecord::Schema.define(version: 20170921104020) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_customers_on_deleted_at"
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
    t.bigint "job_id"
    t.string "status", limit: 10, default: "message"
    t.index ["job_id"], name: "index_histories_on_job_id"
  end

  create_table "jobs", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "resolution"
    t.string "period"
    t.date "start_date"
    t.string "status"
    t.datetime "from"
    t.datetime "to"
    t.json "data"
    t.bigint "vpc_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_reports_on_deleted_at"
    t.index ["start_date"], name: "index_reports_on_start_date"
    t.index ["vpc_id"], name: "index_reports_on_vpc_id"
  end

  create_table "vpcs", force: :cascade do |t|
    t.string "hostname"
    t.datetime "lasterrortime"
    t.integer "lastresponsetime"
    t.datetime "lasttesttime"
    t.string "name"
    t.integer "resolution"
    t.string "status"
    t.json "data"
    t.bigint "customer_id"
    t.string "check_type"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_vpcs_on_customer_id"
    t.index ["deleted_at"], name: "index_vpcs_on_deleted_at"
  end

  add_foreign_key "histories", "jobs"
  add_foreign_key "outages", "reports"
  add_foreign_key "performances", "reports"
  add_foreign_key "reports", "vpcs"
  add_foreign_key "vpcs", "customers"
end
