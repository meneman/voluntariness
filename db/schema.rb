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

ActiveRecord::Schema[8.0].define(version: 2025_06_27_080018) do
  create_table "actions", force: :cascade do |t|
    t.integer "task_id", null: false
    t.integer "participant_id", null: false
    t.datetime "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "on_streak", default: false, null: false
    t.float "bonus_points"
    t.index ["created_at", "participant_id"], name: "index_actions_on_created_at_and_participant_id"
    t.index ["created_at", "task_id"], name: "index_actions_on_created_at_and_task_id"
    t.index ["participant_id", "created_at"], name: "index_actions_on_participant_id_and_created_at"
    t.index ["participant_id"], name: "index_actions_on_participant_id"
    t.index ["task_id"], name: "index_actions_on_task_id"
  end

  create_table "participants", force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.string "avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.integer "user_id", null: false
    t.index ["archived"], name: "index_participants_on_archived"
    t.index ["user_id"], name: "index_participants_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title"
    t.decimal "worth", precision: 10, scale: 2
    t.integer "interval"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.integer "user_id", null: false
    t.integer "position"
    t.index ["archived"], name: "index_tasks_on_archived"
    t.index ["position"], name: "index_tasks_on_position"
    t.index ["user_id"], name: "index_tasks_on_user_id"
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
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "streak_boni_enabled"
    t.integer "streak_boni_days_threshold", default: 5
    t.boolean "overdue_bonus_enabled"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "actions", "participants"
  add_foreign_key "actions", "tasks"
  add_foreign_key "participants", "users"
  add_foreign_key "tasks", "users"
  add_foreign_key "useable_items", "participants"
end
