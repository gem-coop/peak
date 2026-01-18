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

ActiveRecord::Schema[8.2].define(version: 2026_01_18_134138) do
  create_table "namespace_accesses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "namespace_id", null: false
    t.string "role", default: "plain", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["namespace_id"], name: "index_namespace_accesses_on_namespace_id"
    t.index ["user_id"], name: "index_namespace_accesses_on_user_id"
  end

  create_table "namespace_gem_version_metadata", force: :cascade do |t|
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.string "ruby", null: false
    t.string "rubygems"
    t.datetime "updated_at", null: false
    t.integer "version_id", null: false
    t.index ["version_id"], name: "index_namespace_gem_version_metadata_on_version_id", unique: true
  end

  create_table "namespace_gem_version_nodes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "reference_id", null: false
    t.datetime "updated_at", null: false
    t.integer "version_id", null: false
    t.index ["reference_id"], name: "index_namespace_gem_version_nodes_on_reference_id"
    t.index ["version_id", "reference_id"], name: "namespace_gem_version_nodes_uniqueness", unique: true
    t.index ["version_id"], name: "index_namespace_gem_version_nodes_on_version_id"
  end

  create_table "namespace_gem_version_references", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "operator", null: false
    t.string "ref", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "operator", "ref"], name: "namespace_gem_version_references_uniqueness", unique: true
    t.index ["name"], name: "index_namespace_gem_version_references_on_name"
  end

  create_table "namespace_gem_versions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "gem_id", null: false
    t.string "ref", null: false
    t.datetime "updated_at", null: false
    t.index ["gem_id", "ref"], name: "index_namepace_gem_versions_uniqueness", unique: true
    t.index ["gem_id"], name: "index_namespace_gem_versions_on_gem_id"
  end

  create_table "namespace_gems", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "namespace_id", null: false
    t.datetime "updated_at", null: false
    t.index ["namespace_id", "name"], name: "index_namepace_gems_uniqueness", unique: true
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
