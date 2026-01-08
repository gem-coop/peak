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

ActiveRecord::Schema[8.2].define(version: 2026_01_08_091232) do
  create_table "namespace_accesses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "namespace_id", null: false
    t.string "role", default: "plain", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["namespace_id"], name: "index_namespace_accesses_on_namespace_id"
    t.index ["user_id"], name: "index_namespace_accesses_on_user_id"
  end

  create_table "namespace_gems", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "namespace_id", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "namespace_id"], name: "index_namepace_gems_uniqueness", unique: true
    t.index ["namespace_id"], name: "index_namespace_gems_on_namespace_id"
  end

  create_table "namespaces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_namespaces_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end
end
