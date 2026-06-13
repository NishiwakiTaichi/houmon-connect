class CreateScheduleChanges < ActiveRecord::Migration[7.1]
  def change
    create_table :schedule_changes do |t|
      t.references :recurring_visit, null: false, foreign_key: true
      t.references :registered_by, null: false, foreign_key: { to_table: :users } # 登録者
      t.integer :change_type, null: false                        # enum: cancel/reschedule/suspend/resume
      t.date :target_date, null: false                           # 対象日

      # 振替先(change_type = reschedule のとき)
      t.date :new_date
      t.time :new_start_time
      t.time :new_end_time
      t.references :new_user, foreign_key: { to_table: :users }  # 振替担当

      t.integer :reason, null: false                             # enum: hospital_visit/sick/hospitalized/personal/other
      t.text :reason_detail                                      # 理由の補足
      t.integer :cm_contact, null: false, default: 0             # enum: not_contacted/contacted

      t.datetime :confirmed_at                                   # 管理者が確認した日時(null=未確認)
      t.references :confirmed_by, foreign_key: { to_table: :users }
      t.datetime :canceled_at                                    # 取り消した日時(null=有効)
      t.references :canceled_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :schedule_changes, :target_date
    add_index :schedule_changes, :new_date
    add_index :schedule_changes, :canceled_at
    add_index :schedule_changes, :confirmed_at
  end
end
