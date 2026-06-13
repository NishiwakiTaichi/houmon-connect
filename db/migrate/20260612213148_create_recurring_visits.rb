class CreateRecurringVisits < ActiveRecord::Migration[7.1]
  def change
    create_table :recurring_visits do |t|
      t.references :client, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true        # 担当スタッフ
      t.integer :service_type, null: false                      # enum: nursing/rehab
      t.integer :wday, null: false                              # 曜日 0=日..6=土(Date#wdayに合わせる)
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.integer :frequency, null: false, default: 0             # enum: weekly(デフォルト)/nth_weeks/biweekly
      t.string :visit_weeks                                     # 第n週指定 例: "2,4"(nth_weeksのとき)
      t.date :anchor_date                                       # 基準日=直近の訪問日(biweeklyのとき)
      t.datetime :discarded_at                                  # 論理削除(null=有効)

      t.timestamps
    end

    add_index :recurring_visits, :discarded_at
  end
end
