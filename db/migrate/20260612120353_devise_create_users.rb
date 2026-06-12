# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Rememberable
      t.datetime :remember_created_at

      ## アプリ独自のカラム(設計書 2.1 users 参照)
      t.string  :name,   null: false                 # 氏名
      t.integer :role,   null: false, default: 0     # enum: staff(0)/manager(1)
      t.integer :job,    null: false, default: 0     # enum: nurse(0)/pt(1)/ot(2)/st(3)/clerk(4)
      t.boolean :active, null: false, default: true  # 在籍フラグ

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
  end
end
