class ConvertClientStatusToActiveEnded < ActiveRecord::Migration[7.1]
  # status を {active:0, suspended:1, hospitalized:2, ended:3} から {active:0, ended:1} に整理する。
  # 既存の休止中(1)・入院中(2)は休止期間(開始=今日・終了日なし)へ移行し、status は active(0) に。
  # 既存の終了(3)は新しい ended(1) に詰める。生SQLでモデルのenum定義に依存させない。
  def up
    execute <<~SQL
      INSERT INTO client_suspensions (client_id, start_date, note, created_at, updated_at)
      SELECT id, CURRENT_DATE, '入院', NOW(), NOW() FROM clients WHERE status = 2
    SQL
    execute <<~SQL
      INSERT INTO client_suspensions (client_id, start_date, note, created_at, updated_at)
      SELECT id, CURRENT_DATE, '休止', NOW(), NOW() FROM clients WHERE status = 1
    SQL
    execute "UPDATE clients SET status = 0 WHERE status IN (1, 2)"
    execute "UPDATE clients SET status = 1 WHERE status = 3"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
