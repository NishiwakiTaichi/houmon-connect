module StaffAbsencesHelper
  # 休暇種別ラベル（時間休のときは時刻範囲を付加）
  def absence_label(absence)
    base = I18n.t("enums.staff_absence.absence_type.#{absence.absence_type}")
    return base unless absence.hourly?

    "#{base} #{absence.start_time.strftime("%-H:%M")}〜#{absence.end_time.strftime("%-H:%M")}"
  end

  # グリッドセル内の休暇バナー HTML を返す
  def absence_banner(absence)
    css = "absence-banner absence-#{absence.absence_type}"
    tag.div(class: css) do
      tag.span(class: "absence-icon") { "🌙" } +
        tag.span(absence_label(absence), class: "absence-text")
    end
  end
end
