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

ActiveRecord::Schema[8.0].define(version: 2025_05_29_022545) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "title", null: false
    t.text "message", null: false
    t.string "notification_type", null: false
    t.boolean "read", default: false, null: false
    t.datetime "read_at"
    t.string "url"
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "properties", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "address", null: false
    t.string "city", null: false
    t.string "state", null: false
    t.string "zip_code", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "bedrooms", null: false
    t.decimal "bathrooms", precision: 3, scale: 1, null: false
    t.integer "square_feet"
    t.string "property_type", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "availability_status", default: 0, null: false
    t.boolean "parking_available"
    t.boolean "pets_allowed"
    t.boolean "furnished"
    t.boolean "utilities_included"
    t.boolean "laundry"
    t.boolean "gym"
    t.boolean "pool"
    t.boolean "balcony"
    t.boolean "air_conditioning"
    t.boolean "heating"
    t.boolean "internet_included"
    t.integer "status"
    t.index ["availability_status"], name: "index_properties_on_availability_status"
    t.index ["city"], name: "index_properties_on_city"
    t.index ["price"], name: "index_properties_on_price"
    t.index ["property_type"], name: "index_properties_on_property_type"
    t.index ["state"], name: "index_properties_on_state"
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "property_favorites", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "property_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_property_favorites_on_property_id"
    t.index ["user_id", "property_id"], name: "index_property_favorites_on_user_id_and_property_id", unique: true
    t.index ["user_id"], name: "index_property_favorites_on_user_id"
  end

  create_table "property_reviews", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "property_id", null: false
    t.integer "rating", null: false
    t.string "title", null: false
    t.text "content", null: false
    t.boolean "verified", default: false
    t.integer "helpful_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id", "rating"], name: "index_property_reviews_on_property_id_and_rating"
    t.index ["property_id"], name: "index_property_reviews_on_property_id"
    t.index ["user_id", "property_id"], name: "index_property_reviews_on_user_id_and_property_id", unique: true
    t.index ["user_id"], name: "index_property_reviews_on_user_id"
    t.index ["verified"], name: "index_property_reviews_on_verified"
    t.check_constraint "rating >= 1 AND rating <= 5", name: "rating_range_check"
  end

  create_table "property_viewings", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "property_id", null: false
    t.datetime "scheduled_at", null: false
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.string "contact_phone"
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id", "scheduled_at"], name: "index_property_viewings_on_property_id_and_scheduled_at"
    t.index ["property_id"], name: "index_property_viewings_on_property_id"
    t.index ["status"], name: "index_property_viewings_on_status"
    t.index ["user_id", "scheduled_at"], name: "index_property_viewings_on_user_id_and_scheduled_at"
    t.index ["user_id"], name: "index_property_viewings_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "tenant", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "email_verified", default: false, null: false
    t.string "email_verification_token"
    t.datetime "email_verification_sent_at"
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.string "provider"
    t.string "uid"
    t.string "refresh_token"
    t.datetime "refresh_token_expires_at"
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_verification_token"], name: "index_users_on_email_verification_token", unique: true
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["refresh_token"], name: "index_users_on_refresh_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "properties", "users"
  add_foreign_key "property_favorites", "properties"
  add_foreign_key "property_favorites", "users"
  add_foreign_key "property_reviews", "properties"
  add_foreign_key "property_reviews", "users"
  add_foreign_key "property_viewings", "properties"
  add_foreign_key "property_viewings", "users"
end
