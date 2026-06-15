# 変更ログ ページネーション確認用テストデータ生成スクリプト
#
# 【使い方】
# 1. このファイルを houmon_connect/db/ に置く(例: db/seed_activity_logs_demo.rb)
# 2. rails runner で実行:
#      bin/rails runner db/seed_activity_logs_demo.rb
# 3. 変更ログ画面を開くと、120件前後のログが入りページ送りが確認できます
#
# 【特徴】
# - 既存の seed データ(利用者・スタッフ・基本ルート)を使う前提
# - ScheduleChange を多数登録し、一部を確認・取り消しすることでログを量産
# - Current.user を明示的にセットするので、ちゃんと操作者つきでログが残る
# - 何度実行しても、その都度新しいログが増えるだけ(重複エラーにはならない)
#
# 【削除したくなったら】
#   bin/rails runner "ActivityLog.where(action: :create).where('created_at > ?', 1.hour.ago).destroy_all"
#   ※ ただし設計上 ActivityLog に destroy ルートは無いので、これは rails console / runner からのみ

puts "=== 変更ログ デモデータ生成 開始 ==="

# 操作者(管理者)をログのユーザーとして設定
manager = User.find_by(email: "rehab-manager@example.com") || User.where(role: :manager).first
unless manager
  puts "管理者ユーザーが見つかりません。先に通常の seed を実行してください。"
  exit
end
Current.user = manager
puts "操作者: #{manager.name}"

# 有効な基本ルートを取得(論理削除されていないもの)
routes = RecurringVisit.where(discarded_at: nil).to_a
if routes.empty?
  puts "基本ルートがありません。先に通常の seed を実行してください。"
  exit
end
puts "対象の基本ルート: #{routes.size} 件"

reasons = ScheduleChange.reasons.keys
cm_states = ScheduleChange.cm_contacts.keys
created = []

# 100件の変更登録ログを生成(休み・振替を混在)
100.times do |i|
  route = routes.sample
  # 対象日は直近30日のいずれか(その曜日に合わせる)
  base = Date.current + rand(-14..14).days
  target = base

  type = i.even? ? :cancel : :reschedule
  attrs = {
    recurring_visit: route,
    registered_by: manager,
    change_type: type,
    target_date: target,
    reason: reasons.sample,
    reason_detail: [ "", "", "ログ確認用" ].sample,
    cm_contact: cm_states.sample
  }

  if type == :reschedule
    attrs[:new_date] = target + rand(1..5).days
    attrs[:new_start_time] = "%02d:00" % rand(9..16)
    attrs[:new_end_time]   = "%02d:40" % rand(9..16)
    attrs[:new_user_id]    = route.user_id
  end

  sc = ScheduleChange.new(attrs)
  if sc.save
    created << sc
  else
    # バリデーションで弾かれたらスキップ(重複など)
  end
end
puts "変更登録ログ: #{created.size} 件"

# 一部を「確認」してログを追加(20件)
created.sample([ 20, created.size ].min).each do |sc|
  sc.update(confirmed_at: Time.current, confirmed_by: manager)
end
puts "確認ログ: 約20件"

# 一部を「取り消し」してログを追加(15件)
created.sample([ 15, created.size ].min).each do |sc|
  sc.update(canceled_at: Time.current, canceled_by: manager)
end
puts "取り消しログ: 約15件"

Current.user = nil
total = ActivityLog.count
puts "=== 完了 / 現在の総ログ件数: #{total} 件 ==="
puts "変更ログ画面を開くと、50件/ページでページ送りが確認できます。"
