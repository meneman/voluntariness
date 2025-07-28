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

ActiveRecord::Schema[8.0].define(version: 2025_07_28_173506) do
  create_table "action_participants", force: :cascade do |t|
    t.integer "action_id", null: false
    t.integer "participant_id", null: false
    t.decimal "points_earned", precision: 8, scale: 2
    t.decimal "bonus_points", precision: 8, scale: 2, default: "0.0"
    t.boolean "on_streak", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_id", "participant_id"], name: "index_action_participants_on_action_id_and_participant_id", unique: true
    t.index ["action_id"], name: "index_action_participants_on_action_id"
    t.index ["participant_id"], name: "index_action_participants_on_participant_id"
  end

  create_table "actions", force: :cascade do |t|
    t.integer "task_id", null: false
    t.datetime "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at", "task_id"], name: "index_actions_on_created_at_and_task_id"
    t.index ["created_at"], name: "index_actions_on_created_at_and_participant_id"
    t.index ["created_at"], name: "index_actions_on_participant_id_and_created_at"
    t.index ["task_id"], name: "index_actions_on_task_id"
  end

  create_table "bets", force: :cascade do |t|
    t.integer "participant_id", null: false
    t.string "outcome"
    t.decimal "cost", precision: 8, scale: 2
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_bets_on_participant_id"
  end

  create_table "household_memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "household_id", null: false
    t.string "role", default: "member"
    t.boolean "current_household", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["household_id"], name: "index_household_memberships_on_household_id"
    t.index ["user_id", "current_household"], name: "index_household_memberships_on_user_id_and_current_household"
    t.index ["user_id", "household_id"], name: "index_household_memberships_on_user_id_and_household_id", unique: true
    t.index ["user_id"], name: "index_household_memberships_on_user_id"
  end

  create_table "households", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "invite_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invite_code"], name: "index_households_on_invite_code", unique: true
  end

  create_table "participants", force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.string "avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.integer "streak"
    t.boolean "on_streak"
    t.integer "household_id"
    t.index ["archived"], name: "index_participants_on_archived"
    t.index ["household_id"], name: "index_participants_on_household_id"
    t.index ["on_streak"], name: "index_participants_on_on_streak"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title"
    t.integer "worth"
    t.integer "interval"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.integer "position"
    t.integer "household_id"
    t.index ["archived"], name: "index_tasks_on_archived"
    t.index ["household_id"], name: "index_tasks_on_household_id"
    t.index ["position"], name: "index_tasks_on_position"
  end

  create_table "useable_items", force: :cascade do |t|
    t.string "name"
    t.text "svg"
    t.integer "participant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_useable_items_on_participant_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "streak_boni_enabled"
    t.integer "streak_boni_days_threshold", default: 5
    t.boolean "overdue_bonus_enabled"
    t.string "subscription_plan", default: "free"
    t.string "subscription_status", default: "active"
    t.datetime "subscription_purchased_at"
    t.boolean "lifetime_access", default: false
    t.string "role", default: "user", null: false
    t.string "firebase_uid"
    t.string "theme_preference", default: "system"
    t.string "remember_token"
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["firebase_uid"], name: "index_users_on_firebase_uid", unique: true
    t.index ["remember_token"], name: "index_users_on_remember_token"
    t.index ["role"], name: "index_users_on_role"
    t.index ["subscription_plan"], name: "index_users_on_subscription_plan"
    t.index ["subscription_status"], name: "index_users_on_subscription_status"
  end

  add_foreign_key "action_participants", "actions"
  add_foreign_key "action_participants", "participants"
  add_foreign_key "actions", "tasks"
  add_foreign_key "bets", "participants"
  add_foreign_key "household_memberships", "households"
  add_foreign_key "household_memberships", "users"
  add_foreign_key "participants", "households"
  add_foreign_key "tasks", "households"
  add_foreign_key "useable_items", "participants"
end
