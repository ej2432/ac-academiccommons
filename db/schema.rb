# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110914202429) do

  create_table "bookmarks", :force => true do |t|
    t.integer  "user_id",     :null => false
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type"
  end

  create_table "content_blocks", :force => true do |t|
    t.string   "title",      :null => false
    t.integer  "user_id",    :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_blocks", ["title"], :name => "index_content_blocks_on_title"

  create_table "deposits", :force => true do |t|
    t.string   "agreement_version",                    :null => false
    t.string   "uni",                                  :null => false
    t.string   "name",                                 :null => false
    t.string   "email",                                :null => false
    t.string   "file_path",                            :null => false
    t.text     "title",                                :null => false
    t.text     "authors",                              :null => false
    t.text     "abstract",                             :null => false
    t.string   "url"
    t.string   "doi_pmcid"
    t.text     "notes"
    t.boolean  "archived",          :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "email_preferences", :force => true do |t|
    t.string   "author",          :null => false
    t.boolean  "monthly_opt_out"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_preferences", ["author", "monthly_opt_out"], :name => "index_email_preferences_on_author_and_monthly_opt_out"

  create_table "reports", :force => true do |t|
    t.string   "name",         :null => false
    t.string   "category",     :null => false
    t.datetime "generated_on"
    t.integer  "user_id"
    t.text     "options"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reports", ["category"], :name => "index_reports_on_category"

  create_table "searches", :force => true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type"
  end

  add_index "searches", ["user_id"], :name => "index_searches_on_user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "statistics", :force => true do |t|
    t.string   "session_id"
    t.string   "event",      :null => false
    t.string   "ip_address"
    t.string   "identifier"
    t.string   "result"
    t.datetime "at_time",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "statistics", ["at_time"], :name => "index_statistics_on_at_time"
  add_index "statistics", ["event"], :name => "index_statistics_on_event"
  add_index "statistics", ["identifier"], :name => "index_statistics_on_identifier"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.boolean  "admin"
    t.string   "login",                            :null => false
    t.string   "wind_login"
    t.string   "email"
    t.string   "crypted_password"
    t.string   "persistence_token"
    t.integer  "login_count",       :default => 0, :null => false
    t.text     "last_search_url"
    t.datetime "last_login_at"
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.string   "last_login_ip"
    t.string   "current_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["last_request_at"], :name => "index_users_on_last_request_at"
  add_index "users", ["login"], :name => "index_users_on_login"
  add_index "users", ["persistence_token"], :name => "index_users_on_persistence_token"
  add_index "users", ["wind_login"], :name => "index_users_on_wind_login"

end
