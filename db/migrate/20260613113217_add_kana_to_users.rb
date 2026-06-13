class AddKanaToUsers < ActiveRecord::Migration[7.1]
  def change
    # ふりがな。既存行のために default: "" で追加し、seedで実データを入れる
    add_column :users, :kana, :string, null: false, default: ""
  end
end
