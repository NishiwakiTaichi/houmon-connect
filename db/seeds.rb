# ダミーデータ(設計書 9章)
# 実在の利用者・スタッフの情報は一切使用しない。氏名は gimei で自動生成する。
# 何度実行しても安全なように、メールアドレス・件数で重複を避ける。

require "gimei"

def gimei_kanji(name) = "#{name.last.kanji} #{name.first.kanji}"
def gimei_hiragana(name) = "#{name.last.hiragana} #{name.first.hiragana}"

puts "== スタッフアカウント(管理者2名 + 一般6名) =="
staff_defs = [
  # [ メールアドレス, 権限, 職種 ]
  [ "nurse-manager@example.com", :manager, :nurse ],
  [ "rehab-manager@example.com", :manager, :pt ],
  [ "ns1@example.com", :staff, :nurse ],
  [ "ns2@example.com", :staff, :nurse ],
  [ "ns3@example.com", :staff, :nurse ],
  [ "pt1@example.com", :staff, :pt ],
  [ "pt2@example.com", :staff, :pt ],
  [ "ot1@example.com", :staff, :ot ]
]
staff_defs.each do |email, role, job|
  user = User.find_or_create_by!(email: email) do |u|
    u.name = gimei_kanji(Gimei.name)
    u.password = "password"
    u.role = role
    u.job = job
  end
  puts "  #{user.name} (#{email} / #{user.role} / #{user.job})"
end

puts "== 利用者(20名) =="
if Client.count >= 20
  puts "  すでに#{Client.count}名登録済みのためスキップ"
else
  # デモで属性バッジ・状態の違いが一目で伝わるように比率を決め打ちする
  statuses = ([ :active ] * 16 + [ :suspended ] * 2 + [ :hospitalized, :ended ]).shuffle
  newcomer_policies = ([ :ok ] * 13 + [ :needs_contact ] * 4 + [ :ng ] * 3).shuffle
  gender_restrictions = ([ :unrestricted ] * 15 + [ :female_only ] * 4 + [ :male_only ]).shuffle
  notes = [ nil, nil, nil, "鍵は玄関横のキーボックス", "駐車は近隣のコインパーキングを利用", "犬を飼っている(室内)", nil ]

  20.times do |i|
    name = Gimei.name
    client = Client.create!(
      name: gimei_kanji(name),
      kana: gimei_hiragana(name),
      status: statuses[i],
      newcomer_policy: newcomer_policies[i],
      gender_restriction: gender_restrictions[i],
      note: notes.sample
    )
    puts "  #{client.name} (#{client.status} / #{client.newcomer_policy} / #{client.gender_restriction})"
  end
end

puts "seed投入完了: User #{User.count}名 / Client #{Client.count}名"
