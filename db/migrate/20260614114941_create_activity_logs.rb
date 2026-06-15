class CreateActivityLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :activity_logs do |t|
      t.references :user, null: false, foreign_key: true       # 操作したスタッフ
      t.integer :action, null: false                           # enum: create/update/cancel/destroy
      t.references :target, polymorphic: true, null: false     # 対象(利用者/基本ルート/変更/休止期間)
      t.string :summary, null: false                           # 人が読める要約
      t.jsonb :changeset, null: false, default: {}             # 変更前→変更後の差分

      # ログは改変しないため updated_at は持たない(created_at のみ)
      t.datetime :created_at, null: false
    end
  end
end
