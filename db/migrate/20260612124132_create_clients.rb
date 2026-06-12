class CreateClients < ActiveRecord::Migration[7.1]
  def change
    create_table :clients do |t|
      t.string  :name, null: false                              # 氏名
      t.string  :kana, null: false                              # ふりがな
      t.integer :status, null: false, default: 0                # enum: active/suspended/hospitalized/ended
      t.integer :newcomer_policy, null: false, default: 0       # enum: ok/needs_contact/ng(新人同行3区分)
      t.integer :gender_restriction, null: false, default: 0    # enum: unrestricted/female_only/male_only
      t.text    :note                                           # 備考

      t.timestamps
    end
  end
end
