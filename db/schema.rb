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

ActiveRecord::Schema[8.1].define(version: 2026_06_13_200400) do
  create_table "activities", force: :cascade do |t|
    t.datetime "changed_at"
    t.integer "comment_id"
    t.integer "comments_count", default: 0
    t.datetime "created_at", null: false
    t.integer "document_id"
    t.boolean "is_user_only", default: false
    t.integer "other_user_id"
    t.integer "point_id"
    t.integer "priority_id"
    t.string "status", default: "active"
    t.string "type", limit: 80
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["created_at"], name: "index_activities_on_created_at"
    t.index ["priority_id"], name: "index_activities_on_priority_id"
    t.index ["type"], name: "index_activities_on_type"
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "blurbs", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "name", limit: 60
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_blurbs_on_name", unique: true
  end

  create_table "branches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "endorsements_count", default: 0
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "users_count", default: 0
  end

  create_table "changes", force: :cascade do |t|
    t.datetime "approved_at"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "declined_at"
    t.boolean "is_flip", default: false
    t.integer "new_priority_id"
    t.integer "no_votes", default: 0
    t.integer "priority_id"
    t.string "status", default: "sent"
    t.string "type", limit: 60
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "votes_count", default: 0
    t.integer "yes_votes", default: 0
    t.index ["priority_id"], name: "index_changes_on_priority_id"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "activity_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "flags_count", default: 0
    t.boolean "is_endorser", default: false
    t.boolean "is_opposer", default: false
    t.string "status", default: "published"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["activity_id"], name: "index_comments_on_activity_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "documents", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "helpful_count", default: 0
    t.string "name", limit: 140
    t.integer "priority_id"
    t.datetime "published_at"
    t.integer "revisions_count", default: 0
    t.string "status", default: "published"
    t.integer "unhelpful_count", default: 0
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "value", default: 0
    t.index ["priority_id"], name: "index_documents_on_priority_id"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "endorsements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address", limit: 45
    t.integer "position"
    t.integer "priority_id"
    t.integer "score", default: 0
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "value", default: 1
    t.index ["priority_id"], name: "index_endorsements_on_priority_id"
    t.index ["user_id", "priority_id"], name: "index_endorsements_on_user_id_and_priority_id", unique: true
    t.index ["user_id"], name: "index_endorsements_on_user_id"
  end

  create_table "followings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "other_user_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "value", default: 1
    t.index ["user_id", "other_user_id"], name: "index_followings_on_user_id_and_other_user_id", unique: true
  end

  create_table "governments", force: :cascade do |t|
    t.string "briefing_name", default: "Briefing Room"
    t.datetime "created_at", null: false
    t.string "currency_name", default: "political capital"
    t.string "currency_short_name", default: "pc"
    t.integer "documents_count", default: 0
    t.integer "endorsements_count", default: 0
    t.string "homepage", default: "top"
    t.boolean "is_branches", default: false
    t.boolean "is_tags", default: true
    t.string "language_code", default: "en"
    t.string "mission"
    t.string "name", default: "White House"
    t.integer "official_user_id"
    t.integer "points_count", default: 0
    t.integer "priorities_count", default: 0
    t.string "prompt", default: "What do you think the government should do?"
    t.string "tagline"
    t.string "tags_name", default: "Category"
    t.datetime "updated_at", null: false
    t.integer "users_count", default: 0
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "read_at"
    t.integer "recipient_id"
    t.integer "sender_id"
    t.string "status", default: "sent"
    t.string "title", limit: 140
    t.datetime "updated_at", null: false
    t.index ["recipient_id"], name: "index_messages_on_recipient_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "notifiable_id"
    t.string "notifiable_type"
    t.datetime "read_at"
    t.integer "recipient_id"
    t.integer "sender_id"
    t.string "status", default: "unread"
    t.string "type", limit: 80
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "pages", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "link_name", limit: 60
    t.string "name", limit: 100
    t.string "short_name", limit: 60
    t.datetime "updated_at", null: false
    t.index ["short_name"], name: "index_pages_on_short_name", unique: true
  end

  create_table "point_qualities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "point_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.boolean "value", default: true
    t.index ["user_id", "point_id"], name: "index_point_qualities_on_user_id_and_point_id", unique: true
  end

  create_table "points", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "discussions_count", default: 0
    t.integer "helpful_count", default: 0
    t.string "name", limit: 140
    t.integer "other_priority_id"
    t.integer "priority_id"
    t.datetime "published_at"
    t.string "status", default: "published"
    t.integer "unhelpful_count", default: 0
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "value", default: 0
    t.string "website"
    t.index ["priority_id"], name: "index_points_on_priority_id"
    t.index ["status"], name: "index_points_on_status"
    t.index ["user_id"], name: "index_points_on_user_id"
  end

  create_table "priorities", force: :cascade do |t|
    t.string "cached_issue_list"
    t.integer "controversial_score", default: 0
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "discussions_count", default: 0
    t.integer "documents_count", default: 0
    t.integer "down_endorsements_count", default: 0
    t.integer "down_points_count", default: 0
    t.integer "endorsements_count", default: 0
    t.string "ip_address", limit: 45
    t.boolean "is_controversial", default: false
    t.string "name", limit: 140
    t.integer "neutral_points_count", default: 0
    t.integer "official_status", default: 0
    t.integer "official_value", default: 0
    t.integer "points_count", default: 0
    t.integer "position", default: 0
    t.datetime "published_at"
    t.integer "score", default: 0
    t.string "short_url", limit: 40
    t.string "status", default: "published"
    t.datetime "status_changed_at"
    t.integer "trending_score", default: 0
    t.integer "up_endorsements_count", default: 0
    t.integer "up_points_count", default: 0
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["position"], name: "index_priorities_on_position"
    t.index ["status"], name: "index_priorities_on_status"
    t.index ["user_id"], name: "index_priorities_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type", limit: 50
    t.integer "tagger_id"
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", limit: 200
    t.integer "documents_count", default: 0
    t.string "name", limit: 60
    t.integer "points_count", default: 0
    t.integer "priorities_count", default: 0
    t.string "prompt", limit: 100
    t.string "slug", limit: 60
    t.string "title", limit: 60
    t.integer "top_priority_id"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.text "bio"
    t.integer "branch_id"
    t.string "city"
    t.integer "comments_count", default: 0
    t.datetime "created_at", null: false
    t.integer "down_endorsements_count", default: 0
    t.string "email_address", null: false
    t.integer "endorsements_count", default: 0
    t.string "first_name"
    t.integer "followers_count", default: 0
    t.integer "followings_count", default: 0
    t.boolean "is_admin", default: false
    t.string "last_name"
    t.datetime "loggedin_at"
    t.string "login"
    t.string "password_digest", null: false
    t.integer "points_count", default: 0
    t.float "score", default: 1.0
    t.string "state"
    t.string "status", default: "active"
    t.integer "top_endorsement_id"
    t.integer "up_endorsements_count", default: 0
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["branch_id"], name: "index_users_on_branch_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["login"], name: "index_users_on_login", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.integer "change_id"
    t.datetime "created_at", null: false
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "value", default: 1
    t.datetime "voted_at"
    t.index ["change_id", "user_id"], name: "index_votes_on_change_id_and_user_id", unique: true
    t.index ["change_id"], name: "index_votes_on_change_id"
  end

  add_foreign_key "sessions", "users"
end
