class CreateClientSuspensions < ActiveRecord::Migration[7.1]
  def change
    create_table :client_suspensions do |t|
      t.references :client, null: false, foreign_key: true
      t.date :start_date, null: false           # 休止開始日(必須)
      t.date :end_date                          # 休止終了日(任意。空=開始日以降ずっと休止)
      t.string :note                            # 理由メモ(任意。「入院」など)

      t.timestamps
    end

    add_index :client_suspensions, [ :client_id, :start_date ]
  end
end
