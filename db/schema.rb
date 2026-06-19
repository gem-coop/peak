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

ActiveRecord::Schema[8.1].define(version: 2026_06_19_000005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "namespace_accesses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "namespace_id", null: false
    t.string "role", default: "plain", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["namespace_id"], name: "index_namespace_accesses_on_namespace_id"
    t.index ["user_id"], name: "index_namespace_accesses_on_user_id"
  end

  create_table "namespace_gem_infos", force: :cascade do |t|
    t.string "checksum", default: "", null: false
    t.text "contents", default: "", null: false
    t.datetime "created_at", null: false
    t.string "envelope", default: "", null: false
    t.bigint "gem_id", null: false
    t.datetime "updated_at", null: false
    t.index ["gem_id"], name: "index_namespace_gem_infos_on_gem_id"
  end

  create_table "namespace_gem_version_linkings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "link_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "version_id", null: false
    t.index ["link_id"], name: "index_namespace_gem_version_linkings_on_link_id"
    t.index ["version_id", "link_id"], name: "index_namespace_gem_version_linking_uniqueness", unique: true
    t.index ["version_id"], name: "index_namespace_gem_version_linkings_on_version_id"
  end

  create_table "namespace_gem_version_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["key", "value"], name: "namespace_gem_version_links_uniqueness", unique: true
  end

  create_table "namespace_gem_version_metadata", force: :cascade do |t|
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.string "ruby", null: false
    t.string "rubygems"
    t.datetime "updated_at", null: false
    t.bigint "version_id", null: false
    t.index ["version_id"], name: "index_namespace_gem_version_metadata_on_version_id", unique: true
  end

  create_table "namespace_gem_version_nodes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "reference_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "version_id", null: false
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
    t.bigint "created_by_id", null: false
    t.string "created_by_type", default: "User", null: false
    t.json "executables", default: [], null: false
    t.bigint "gem_id", null: false
    t.boolean "has_extensions"
    t.json "licenses", default: [], null: false
    t.string "line", null: false
    t.bigint "platform_id", null: false
    t.datetime "published_at", null: false
    t.string "ref", null: false
    t.string "ruby"
    t.string "rubygems"
    t.string "summary", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_namespace_gem_versions_on_created_by_id"
    t.index ["created_by_type", "created_by_id"], name: "idx_on_created_by_type_created_by_id_c48d949be2"
    t.index ["gem_id", "ref"], name: "index_namepace_gem_versions_uniqueness", unique: true
    t.index ["gem_id"], name: "index_namespace_gem_versions_on_gem_id"
    t.index ["platform_id"], name: "index_namespace_gem_versions_on_platform_id"
  end

  create_table "namespace_gems", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "index_id", null: false
    t.string "name", null: false
    t.bigint "namespace_id", null: false
    t.datetime "trim_versions_published_at"
    t.datetime "updated_at", null: false
    t.index ["index_id", "name"], name: "index_namepace_gems_uniqueness", unique: true
    t.index ["index_id"], name: "index_namespace_gems_on_index_id"
    t.index ["namespace_id"], name: "index_namespace_gems_on_namespace_id"
  end

  create_table "namespace_index_cooldown_projections", force: :cascade do |t|
    t.datetime "append_at", null: false
    t.bigint "cooldown_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "version_id", null: false
    t.index ["cooldown_id", "version_id"], name: "idx_on_cooldown_id_version_id_07dae4f703", unique: true
    t.index ["cooldown_id"], name: "index_namespace_index_cooldown_projections_on_cooldown_id"
  end

  create_table "namespace_index_cooldowns", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "index_id", null: false
    t.interval "interval", default: "P2D", null: false
    t.datetime "refreshed_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", null: false
    t.index ["index_id", "interval"], name: "index_namespace_index_cooldowns_on_index_id_and_interval", unique: true
  end

  create_table "namespace_index_manifests", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.string "author_type", null: false
    t.datetime "compacted_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "contents", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_namespace_index_manifests_on_author", unique: true
  end

  create_table "namespace_indexes", force: :cascade do |t|
    t.string "access", default: "public", null: false
    t.datetime "created_at", null: false
    t.bigint "namespace_id", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["namespace_id", "slug"], name: "namespace_index_uniqueness", unique: true
    t.index ["namespace_id"], name: "index_namespace_indexes_on_namespace_id"
  end

  create_table "namespaces", force: :cascade do |t|
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_at"], name: "index_namespaces_on_approved_at"
    t.index ["name"], name: "index_namespaces_on_name", unique: true
  end

  create_table "oidc_id_tokens", force: :cascade do |t|
    t.json "claims", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "jti", null: false
    t.bigint "provider_id", null: false
    t.bigint "push_key_id"
    t.bigint "trusted_publisher_id", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id", "jti"], name: "index_oidc_id_tokens_on_provider_id_and_jti", unique: true
    t.index ["provider_id"], name: "index_oidc_id_tokens_on_provider_id"
    t.index ["push_key_id"], name: "index_oidc_id_tokens_on_push_key_id"
    t.index ["trusted_publisher_id"], name: "index_oidc_id_tokens_on_trusted_publisher_id"
  end

  create_table "oidc_providers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "issuer", null: false
    t.string "name", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["issuer"], name: "index_oidc_providers_on_issuer", unique: true
  end

  create_table "peak_platforms", force: :cascade do |t|
    t.string "arch", null: false
    t.datetime "created_at", null: false
    t.string "key"
    t.string "name", null: false
    t.boolean "precompile_target", default: false, null: false
    t.string "specifier", null: false
    t.datetime "updated_at", null: false
    t.index ["arch", "name", "precompile_target"], name: "index_peak_platforms_on_arch_and_name_and_precompile_target"
    t.index ["key"], name: "peak_platforms_uniqueness", unique: true
  end

  create_table "peak_terms", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "status", default: "drafted", null: false
    t.datetime "updated_at", null: false
  end

  create_table "peak_terms_acceptances", force: :cascade do |t|
    t.boolean "accepted", default: false, null: false
    t.datetime "captured_at", null: false
    t.datetime "created_at", null: false
    t.string "sha", null: false
    t.bigint "terms_id", null: false
    t.string "time_zone", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["terms_id"], name: "index_peak_terms_acceptances_on_terms_id"
    t.index ["user_id"], name: "index_peak_terms_acceptances_on_user_id"
  end

  create_table "trusted_publisher_push_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token_digest", null: false
    t.bigint "trusted_publisher_id", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_trusted_publisher_push_keys_on_token_digest", unique: true
    t.index ["trusted_publisher_id"], name: "index_trusted_publisher_push_keys_on_trusted_publisher_id"
  end

  create_table "trusted_publishers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "environment"
    t.bigint "gem_id"
    t.string "gem_name", null: false
    t.bigint "namespace_id", null: false
    t.bigint "provider_id", null: false
    t.string "ref"
    t.string "repository_name"
    t.string "repository_owner"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.string "workflow_filename"
    t.index ["gem_id"], name: "index_trusted_publishers_on_gem_id"
    t.index ["namespace_id"], name: "index_trusted_publishers_on_namespace_id"
    t.index ["provider_id"], name: "index_trusted_publishers_on_provider_id"
  end

  create_table "user_push_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_push_keys_on_user_id"
  end

  create_table "user_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address", null: false
    t.datetime "resumed_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "email_address_verified_at"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "oidc_id_tokens", "oidc_providers", column: "provider_id"
  add_foreign_key "oidc_id_tokens", "trusted_publisher_push_keys", column: "push_key_id"
  add_foreign_key "oidc_id_tokens", "trusted_publishers"
  add_foreign_key "trusted_publisher_push_keys", "trusted_publishers"
  add_foreign_key "trusted_publishers", "namespace_gems", column: "gem_id"
  add_foreign_key "trusted_publishers", "namespaces"
  add_foreign_key "trusted_publishers", "oidc_providers", column: "provider_id"
end
