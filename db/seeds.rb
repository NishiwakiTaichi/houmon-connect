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
  user = User.find_or_initialize_by(email: email)
  # 新規、またはふりがな未設定の既存スタッフは、氏名とふりがなを一組で生成し直す
  if user.new_record? || user.kana.blank?
    gimei = Gimei.name
    user.name = gimei_kanji(gimei)
    user.kana = gimei_hiragana(gimei)
  end
  user.password = "password" if user.new_record?
  user.role = role
  user.job = job
  user.save!
  puts "  #{user.name}(#{user.kana}) (#{email} / #{user.role} / #{user.job})"
end

puts "== 利用者(20名) =="
if Client.count >= 20
  puts "  すでに#{Client.count}名登録済みのためスキップ"
else
  # デモで属性バッジ・状態の違いが一目で伝わるように比率を決め打ちする
  # status は契約状態(利用中/終了)のみ。休止は休止期間で表現する
  statuses = ([ :active ] * 19 + [ :ended ]).shuffle
  newcomer_policies = ([ :ok ] * 13 + [ :needs_contact ] * 4 + [ :ng ] * 3).shuffle
  gender_restrictions = ([ :unrestricted ] * 15 + [ :female_only ] * 4 + [ :male_only ]).shuffle
  notes = [ nil, nil, nil, "鍵は玄関横のキーボックス", "駐車は近隣のコインパーキングを利用", "犬を飼っている(室内)", nil ]

  clients = 20.times.map do |i|
    name = Gimei.name
    Client.create!(
      name: gimei_kanji(name),
      kana: gimei_hiragana(name),
      status: statuses[i],
      newcomer_policy: newcomer_policies[i],
      gender_restriction: gender_restrictions[i],
      note: notes.sample
    )
  end
  puts "  #{clients.size}名登録"

  # 休止期間のデモ: 現在進行中(終了日なし=入院)・期間指定・将来予定の3パターン
  active = clients.select(&:active?)
  today = Date.current
  ClientSuspension.create!(client: active[0], start_date: today - 5, note: "入院")                       # 継続中(入院)
  ClientSuspension.create!(client: active[1], start_date: today - 2, end_date: today + 5, note: "家族の都合") # 今まさに休止中
  ClientSuspension.create!(client: active[2], start_date: today + 7, end_date: today + 14, note: "施設ショートステイ") # 将来の予定
  puts "  休止期間 #{ClientSuspension.count}件"
end

puts "== 基本ルート =="
if RecurringVisit.any?
  puts "  すでに#{RecurringVisit.count}件登録済みのためスキップ"
else
  # 看護職は看護、PT/OTはリハビリを担当。事務はルートを持たない
  field_staff = User.where.not(job: :clerk)
  active_clients = Client.active.to_a
  start_times = [ "9:00", "10:00", "11:00", "13:30", "14:30", "15:30" ]
  base_monday = Date.new(2026, 6, 8) # 基準日計算用の月曜(過去の週)

  field_staff.each do |staff|
    service = staff.nurse? ? :nursing : :rehab
    (1..5).each do |wday| # 月〜金
      start_times.sample(rand(3..5)).each do |start|
        start_at = Time.zone.parse(start)
        frequency = [ :weekly, :weekly, :weekly, :weekly, :nth_weeks, :biweekly ].sample
        anchor = base_monday + (wday - 1) - [ 0, 7 ].sample # 週の位相をばらす
        RecurringVisit.create!(
          client: active_clients.sample,
          user: staff,
          service_type: service,
          wday: wday,
          start_time: start_at,
          end_time: start_at + 40.minutes,
          frequency: frequency,
          visit_weeks: (frequency == :nth_weeks ? [ "1,3", "2,4" ].sample : nil),
          anchor_date: (frequency == :biweekly ? anchor : nil)
        )
      end
    end
  end
  puts "  #{RecurringVisit.count}件登録(毎週 #{RecurringVisit.weekly.count} / 第n週 #{RecurringVisit.nth_weeks.count} / 2週ごと #{RecurringVisit.biweekly.count})"
end

puts "seed投入完了: User #{User.count}名 / Client #{Client.count}名 / RecurringVisit #{RecurringVisit.count}件"
