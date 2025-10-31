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

ActiveRecord::Schema[8.2].define(version: 2025_10_30_222445) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "indexed_files", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.string "content_type", null: false, comment: "Detected media type"
    t.datetime "created_at", null: false
    t.string "filename", null: false, comment: "original filename"
    t.string "key", null: false, comment: "quick identifier, calculated by `storage_path`"
    t.datetime "modified_at", precision: nil, null: false, comment: "original file's `mtime` attribute"
    t.string "storage_path", null: false, comment: "original storage path (relative to the root)"
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_indexed_files_on_key"
    t.index ["storage_path"], name: "index_indexed_files_on_storage_path", unique: true
  end
end
