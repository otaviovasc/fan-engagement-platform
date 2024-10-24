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

ActiveRecord::Schema[7.0].define(version: 2024_10_24_214010) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "artist_stats", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "artist_id", null: false
    t.integer "points", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "processed_videos", default: [], array: true
    t.index ["artist_id"], name: "index_artist_stats_on_artist_id"
    t.index ["user_id"], name: "index_artist_stats_on_user_id"
  end

  create_table "artists", force: :cascade do |t|
    t.string "spotify_id"
    t.string "name"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "youtube_id"
    t.index ["name"], name: "artists_name_trgm_idx", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "user_waitlists", force: :cascade do |t|
    t.string "email"
    t.boolean "confirmed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "spotify_id"
    t.string "display_name"
    t.string "access_token"
    t.string "refresh_token"
    t.string "profile_image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "youtube_id"
    t.string "youtube_access_token"
    t.string "youtube_refresh_token"
  end

  add_foreign_key "artist_stats", "artists"
  add_foreign_key "artist_stats", "users"
end
