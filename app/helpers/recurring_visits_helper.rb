module RecurringVisitsHelper
  WDAY_NAMES = %w[日 月 火 水 木 金 土].freeze
  # フォーム・一覧は月始まりで表示する(仕様書 F-6: 曜日は月〜日)
  WDAYS_MON_START = [ 1, 2, 3, 4, 5, 6, 0 ].freeze

  def wday_name(wday)
    WDAY_NAMES[wday]
  end

  def visit_time_range(visit)
    "#{visit.start_time.strftime("%-H:%M")}〜#{visit.end_time.strftime("%-H:%M")}"
  end

  # 「毎週」「第2・4週」「2週ごと(基準 6/2)」のような表示用ラベル
  def frequency_label(visit)
    case visit.frequency.to_sym
    when :weekly
      enum_t(visit, :frequency)
    when :nth_weeks
      "第#{visit.visit_week_numbers.join("・")}週"
    when :biweekly
      "2週ごと(基準 #{l(visit.anchor_date, format: :short)})"
    end
  end

  def service_type_badge(visit)
    css = visit.nursing? ? "svc-nursing" : "svc-rehab"
    tag.span(enum_t(visit, :service_type), class: "status-badge #{css}")
  end
end
