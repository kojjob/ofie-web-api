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

ActiveRecord::Schema[8.0].define(version: 2025_05_30_200013) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
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

  create_table "bot_context_stores", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.bigint "conversation_id"
    t.string "session_id", null: false
    t.json "context_data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_bot_context_stores_on_conversation_id"
    t.index ["session_id"], name: "index_bot_context_stores_on_session_id"
    t.index ["updated_at"], name: "index_bot_context_stores_on_updated_at"
    t.index ["user_id", "conversation_id"], name: "index_bot_context_on_user_and_conversation", unique: true
    t.index ["user_id"], name: "index_bot_context_stores_on_user_id"
  end

  create_table "bot_feedbacks", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.bigint "message_id", null: false
    t.string "feedback_type", null: false
    t.text "details"
    t.json "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_bot_feedbacks_on_created_at"
    t.index ["feedback_type", "created_at"], name: "index_bot_feedbacks_on_feedback_type_and_created_at"
    t.index ["feedback_type"], name: "index_bot_feedbacks_on_feedback_type"
    t.index ["message_id"], name: "index_bot_feedbacks_on_message_id"
    t.index ["user_id"], name: "index_bot_feedbacks_on_user_id"
  end

  create_table "bot_learning_data", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.text "message", null: false
    t.string "intent", null: false
    t.decimal "confidence", precision: 5, scale: 4, null: false
    t.json "entities"
    t.json "context"
    t.string "session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_bot_learning_data_on_created_at"
    t.index ["intent", "confidence"], name: "index_bot_learning_data_on_intent_and_confidence"
    t.index ["intent"], name: "index_bot_learning_data_on_intent"
    t.index ["session_id"], name: "index_bot_learning_data_on_session_id"
    t.index ["user_id", "created_at"], name: "index_bot_learning_data_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_bot_learning_data_on_user_id"
  end

  create_table "comment_likes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "property_comment_id", null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["property_comment_id"], name: "index_comment_likes_on_property_comment_id"
    t.index ["user_id", "property_comment_id"], name: "index_comment_likes_on_user_id_and_property_comment_id", unique: true
  end

  create_table "conversations", force: :cascade do |t|
    t.uuid "landlord_id", null: false
    t.uuid "tenant_id", null: false
    t.uuid "property_id", null: false
    t.string "subject"
    t.string "status", default: "active"
    t.datetime "last_message_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "metadata"
    t.index ["landlord_id", "tenant_id", "property_id"], name: "index_conversations_on_participants_and_property", unique: true
    t.index ["landlord_id"], name: "index_conversations_on_landlord_id"
    t.index ["last_message_at"], name: "index_conversations_on_last_message_at"
    t.index ["property_id"], name: "index_conversations_on_property_id"
    t.index ["status"], name: "index_conversations_on_status"
    t.index ["tenant_id"], name: "index_conversations_on_tenant_id"
  end

  create_table "lease_agreements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "rental_application_id", null: false
    t.uuid "landlord_id", null: false
    t.uuid "tenant_id", null: false
    t.uuid "property_id", null: false
    t.date "lease_start_date", null: false
    t.date "lease_end_date", null: false
    t.decimal "monthly_rent", precision: 10, scale: 2, null: false
    t.decimal "security_deposit_amount", precision: 10, scale: 2
    t.string "status", default: "draft"
    t.text "terms_and_conditions"
    t.datetime "signed_by_tenant_at"
    t.datetime "signed_by_landlord_at"
    t.string "document_url"
    t.string "lease_number"
    t.json "additional_terms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["landlord_id"], name: "index_lease_agreements_on_landlord_id"
    t.index ["lease_end_date"], name: "index_lease_agreements_on_lease_end_date"
    t.index ["lease_number"], name: "index_lease_agreements_on_lease_number", unique: true
    t.index ["lease_start_date"], name: "index_lease_agreements_on_lease_start_date"
    t.index ["property_id"], name: "index_lease_agreements_on_property_id"
    t.index ["rental_application_id"], name: "index_lease_agreements_on_rental_application_id", unique: true
    t.index ["status"], name: "index_lease_agreements_on_status"
    t.index ["tenant_id"], name: "index_lease_agreements_on_tenant_id"
  end

  create_table "maintenance_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "property_id", null: false
    t.uuid "tenant_id", null: false
    t.uuid "landlord_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.string "priority", default: "medium"
    t.string "status", default: "pending"
    t.string "category"
    t.text "location_details"
    t.decimal "estimated_cost", precision: 10, scale: 2
    t.datetime "requested_at", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "scheduled_at"
    t.datetime "completed_at"
    t.uuid "assigned_to_id"
    t.text "landlord_notes"
    t.text "completion_notes"
    t.boolean "urgent", default: false
    t.boolean "tenant_present_required", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_maintenance_requests_on_category"
    t.index ["landlord_id"], name: "index_maintenance_requests_on_landlord_id"
    t.index ["priority"], name: "index_maintenance_requests_on_priority"
    t.index ["property_id"], name: "index_maintenance_requests_on_property_id"
    t.index ["requested_at"], name: "index_maintenance_requests_on_requested_at"
    t.index ["status"], name: "index_maintenance_requests_on_status"
    t.index ["tenant_id"], name: "index_maintenance_requests_on_tenant_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.uuid "sender_id", null: false
    t.text "content", null: false
    t.string "message_type", default: "text"
    t.boolean "read", default: false
    t.string "attachment_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "read_at"
    t.json "metadata"
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
    t.index ["sender_id", "read"], name: "index_messages_on_sender_id_and_read"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
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

  create_table "payment_methods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "stripe_payment_method_id", null: false
    t.string "payment_type", null: false
    t.string "last_four"
    t.string "brand"
    t.integer "exp_month"
    t.integer "exp_year"
    t.boolean "is_default", default: false
    t.string "billing_name"
    t.json "billing_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_payment_method_id"], name: "index_payment_methods_on_stripe_payment_method_id", unique: true
    t.index ["user_id", "is_default"], name: "index_payment_methods_on_user_id_and_is_default"
    t.index ["user_id"], name: "index_payment_methods_on_user_id"
  end

  create_table "payment_schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lease_agreement_id", null: false
    t.string "payment_type", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "frequency", null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.date "next_payment_date", null: false
    t.boolean "is_active", default: true
    t.boolean "auto_pay", default: false
    t.integer "day_of_month"
    t.text "description"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auto_pay"], name: "index_payment_schedules_on_auto_pay"
    t.index ["is_active"], name: "index_payment_schedules_on_is_active"
    t.index ["lease_agreement_id", "payment_type"], name: "index_payment_schedules_on_lease_agreement_id_and_payment_type"
    t.index ["lease_agreement_id"], name: "index_payment_schedules_on_lease_agreement_id"
    t.index ["next_payment_date"], name: "index_payment_schedules_on_next_payment_date"
    t.index ["payment_type"], name: "index_payment_schedules_on_payment_type"
  end

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lease_agreement_id", null: false
    t.uuid "user_id", null: false
    t.uuid "payment_method_id"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "payment_type", null: false
    t.string "status", default: "pending"
    t.string "stripe_payment_intent_id"
    t.string "stripe_charge_id"
    t.string "description"
    t.date "due_date"
    t.datetime "paid_at"
    t.string "failure_reason"
    t.json "metadata"
    t.string "payment_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_payments_on_due_date"
    t.index ["lease_agreement_id"], name: "index_payments_on_lease_agreement_id"
    t.index ["paid_at"], name: "index_payments_on_paid_at"
    t.index ["payment_method_id"], name: "index_payments_on_payment_method_id"
    t.index ["payment_number"], name: "index_payments_on_payment_number", unique: true
    t.index ["payment_type"], name: "index_payments_on_payment_type"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["stripe_payment_intent_id"], name: "index_payments_on_stripe_payment_intent_id", unique: true
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "properties", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "address", null: false
    t.string "city", null: false
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
    t.decimal "latitude"
    t.decimal "longitude"
    t.decimal "score", precision: 8, scale: 2, default: "0.0"
    t.integer "views_count", default: 0
    t.integer "applications_count", default: 0
    t.integer "favorites_count", default: 0
    t.index ["availability_status"], name: "index_properties_on_availability_status"
    t.index ["city", "property_type"], name: "index_properties_on_city_and_property_type"
    t.index ["city"], name: "index_properties_on_city"
    t.index ["price", "bedrooms", "bathrooms"], name: "index_properties_on_price_and_bedrooms_and_bathrooms"
    t.index ["price"], name: "index_properties_on_price"
    t.index ["property_type"], name: "index_properties_on_property_type"
    t.index ["score", "created_at"], name: "index_properties_on_score_and_created_at"
    t.index ["score"], name: "index_properties_on_score"
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "property_comments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "property_id", null: false
    t.uuid "parent_id"
    t.text "content", null: false
    t.boolean "edited", default: false
    t.datetime "edited_at", precision: nil
    t.integer "likes_count", default: 0
    t.boolean "flagged", default: false
    t.string "flagged_reason"
    t.datetime "flagged_at", precision: nil
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["flagged"], name: "index_property_comments_on_flagged"
    t.index ["parent_id"], name: "index_property_comments_on_parent_id"
    t.index ["property_id", "created_at"], name: "index_property_comments_on_property_id_and_created_at"
    t.index ["user_id", "created_at"], name: "index_property_comments_on_user_id_and_created_at"
    t.check_constraint "length(content) >= 1 AND length(content) <= 2000", name: "content_length_check"
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
    t.integer "viewing_type"
    t.index ["property_id", "scheduled_at"], name: "index_property_viewings_on_property_id_and_scheduled_at"
    t.index ["property_id"], name: "index_property_viewings_on_property_id"
    t.index ["status"], name: "index_property_viewings_on_status"
    t.index ["user_id", "scheduled_at"], name: "index_property_viewings_on_user_id_and_scheduled_at"
    t.index ["user_id"], name: "index_property_viewings_on_user_id"
  end

  create_table "rental_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "property_id", null: false
    t.uuid "tenant_id", null: false
    t.string "status", default: "pending"
    t.datetime "application_date", default: -> { "CURRENT_TIMESTAMP" }
    t.date "move_in_date"
    t.decimal "monthly_income", precision: 10, scale: 2
    t.string "employment_status"
    t.text "previous_address"
    t.text "references_contact"
    t.text "additional_notes"
    t.boolean "documents_verified", default: false
    t.integer "credit_score"
    t.datetime "reviewed_at"
    t.uuid "reviewed_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_date"], name: "index_rental_applications_on_application_date"
    t.index ["property_id"], name: "index_rental_applications_on_property_id"
    t.index ["status"], name: "index_rental_applications_on_status"
    t.index ["tenant_id"], name: "index_rental_applications_on_tenant_id"
  end

  create_table "security_deposits", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lease_agreement_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "status", default: "pending"
    t.datetime "collected_at"
    t.datetime "refunded_at"
    t.decimal "refund_amount", precision: 10, scale: 2
    t.json "deductions"
    t.string "stripe_payment_intent_id"
    t.string "stripe_refund_id"
    t.text "refund_reason"
    t.text "collection_notes"
    t.json "inspection_report"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collected_at"], name: "index_security_deposits_on_collected_at"
    t.index ["lease_agreement_id"], name: "index_security_deposits_on_lease_agreement_id", unique: true
    t.index ["refunded_at"], name: "index_security_deposits_on_refunded_at"
    t.index ["status"], name: "index_security_deposits_on_status"
    t.index ["stripe_payment_intent_id"], name: "index_security_deposits_on_stripe_payment_intent_id"
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
    t.string "stripe_customer_id"
    t.text "bio"
    t.string "phone"
    t.string "language"
    t.string "timezone"
    t.string "avatar"
    t.json "preferences"
    t.datetime "last_seen_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_verification_token"], name: "index_users_on_email_verification_token", unique: true
    t.index ["last_seen_at"], name: "index_users_on_last_seen_at"
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["refresh_token"], name: "index_users_on_refresh_token", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bot_context_stores", "conversations"
  add_foreign_key "bot_context_stores", "users"
  add_foreign_key "bot_feedbacks", "messages"
  add_foreign_key "bot_feedbacks", "users"
  add_foreign_key "bot_learning_data", "users"
  add_foreign_key "comment_likes", "property_comments", name: "comment_likes_property_comment_id_fkey"
  add_foreign_key "comment_likes", "users", name: "comment_likes_user_id_fkey"
  add_foreign_key "conversations", "properties"
  add_foreign_key "conversations", "users", column: "landlord_id"
  add_foreign_key "conversations", "users", column: "tenant_id"
  add_foreign_key "lease_agreements", "properties"
  add_foreign_key "lease_agreements", "rental_applications"
  add_foreign_key "lease_agreements", "users", column: "landlord_id"
  add_foreign_key "lease_agreements", "users", column: "tenant_id"
  add_foreign_key "maintenance_requests", "properties"
  add_foreign_key "maintenance_requests", "users", column: "assigned_to_id"
  add_foreign_key "maintenance_requests", "users", column: "landlord_id"
  add_foreign_key "maintenance_requests", "users", column: "tenant_id"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "payment_methods", "users"
  add_foreign_key "payment_schedules", "lease_agreements"
  add_foreign_key "payments", "lease_agreements"
  add_foreign_key "payments", "payment_methods"
  add_foreign_key "payments", "users"
  add_foreign_key "properties", "users"
  add_foreign_key "property_comments", "properties", name: "property_comments_property_id_fkey"
  add_foreign_key "property_comments", "property_comments", column: "parent_id", name: "property_comments_parent_id_fkey"
  add_foreign_key "property_comments", "users", name: "property_comments_user_id_fkey"
  add_foreign_key "property_favorites", "properties"
  add_foreign_key "property_favorites", "users"
  add_foreign_key "property_reviews", "properties"
  add_foreign_key "property_reviews", "users"
  add_foreign_key "property_viewings", "properties"
  add_foreign_key "property_viewings", "users"
  add_foreign_key "rental_applications", "properties"
  add_foreign_key "rental_applications", "users", column: "reviewed_by_id"
  add_foreign_key "rental_applications", "users", column: "tenant_id"
  add_foreign_key "security_deposits", "lease_agreements"
end
