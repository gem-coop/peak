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

ActiveRecord::Schema[8.1].define(version: 2026_01_25_161937) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cooldown_versions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "info_byte"
    t.string "name"
    t.datetime "published_at"
    t.datetime "updated_at", null: false
    t.string "version"
    t.bigint "versions_byte"
    t.datetime "yanked_at"
    t.index ["name", "version"], name: "index_cooldown_versions_on_name_and_version", unique: true
    t.index ["published_at"], name: "index_cooldown_versions_on_published_at"
  end

  create_table "namespace_accesses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "namespace_id", null: false
    t.string "role", default: "plain", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["namespace_id"], name: "index_namespace_accesses_on_namespace_id"
    t.index ["user_id"], name: "index_namespace_accesses_on_user_id"
  end

  create_table "namespace_gem_infos", force: :cascade do |t|
    t.string "checksum", default: "", null: false
    t.text "contents", default: "", null: false
    t.datetime "created_at", null: false
    t.string "envelope", default: "", null: false
    t.integer "gem_id", null: false
    t.datetime "updated_at", null: false
    t.index ["gem_id"], name: "index_namespace_gem_infos_on_gem_id"
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
    t.string "checksum"
    t.datetime "created_at", null: false
    t.integer "gem_id", null: false
    t.datetime "published_at", null: false
    t.string "ref", null: false
    t.string "ruby"
    t.string "rubygems"
    t.datetime "updated_at", null: false
    t.index ["gem_id", "ref"], name: "index_namepace_gem_versions_uniqueness", unique: true
    t.index ["gem_id"], name: "index_namespace_gem_versions_on_gem_id"
  end

  create_table "namespace_gems", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "index_id", null: false
    t.string "name", null: false
    t.integer "namespace_id", null: false
    t.datetime "trim_versions_published_at"
    t.datetime "updated_at", null: false
    t.index ["index_id", "name"], name: "index_namepace_gems_uniqueness", unique: true
    t.index ["index_id"], name: "index_namespace_gems_on_index_id"
    t.index ["namespace_id"], name: "index_namespace_gems_on_namespace_id"
  end

  create_table "namespace_indexes", force: :cascade do |t|
    t.string "access", default: "external", null: false
    t.datetime "created_at", null: false
    t.datetime "last_compacted_at", null: false
    t.integer "namespace_id", null: false
    t.datetime "updated_at", null: false
    t.text "versions_contents", default: "---\n", null: false
    t.index ["namespace_id"], name: "index_namespace_indexes_on_namespace_id"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
