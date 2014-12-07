# encoding: UTF-8
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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141206210909) do

  create_table "accounts", force: true do |t|
    t.integer  "user_id"
    t.float    "balance"
    t.boolean  "acct_type"
    t.float    "threshold"
    t.boolean  "is_threshold"
    t.boolean  "is_receiving"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "existence",            default: true
    t.boolean  "is_default_receiving"
  end

  create_table "histories", force: true do |t|
    t.integer  "acct_id"
    t.float    "balance"
    t.integer  "cd"
    t.float    "amount"
    t.boolean  "cs"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password_digest"
    t.string   "remember_token"
    t.boolean  "admin"
    t.boolean  "existence",            default: true
    t.integer  "default_receiving_ID"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["remember_token"], name: "index_users_on_remember_token"

end
