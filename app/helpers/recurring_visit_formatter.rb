module RecurringVisitFormatter
  extend self

  WDAY_JA = %w[日 月 火 水 木 金 土].freeze

  # 曜日番号(0〜6) → 「月」「火」などの日本語名
  def fmt_wday(n)
    WDAY_JA[n.to_i]
  end

  # RecurringVisit の time 型フィールドを「15:30」形式に整形。
  # DBからの ISO 文字列・Time オブジェクトどちらも受け取る。
  def fmt_visit_time(value)
    t = value.is_a?(String) ? Time.zone.parse(value) : value
    t.strftime("%-H:%M")
  end

  # ルート1行テキスト: 「火 10:00〜10:40 担当: 山田」
  def fmt_route(wday, start_time, end_time, user_name)
    "#{fmt_wday(wday)} #{fmt_visit_time(start_time)}〜#{fmt_visit_time(end_time)} 担当: #{user_name}"
  end
end
