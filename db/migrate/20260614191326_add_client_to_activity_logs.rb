class AddClientToActivityLogs < ActiveRecord::Migration[7.1]
  # ログを利用者名で横断検索するため、対象に紐づく利用者を非正規化して保持する。
  # (対象が物理削除されても検索できるよう、target とは別に持つ)
  def change
    add_reference :activity_logs, :client, null: true, foreign_key: true
  end
end
