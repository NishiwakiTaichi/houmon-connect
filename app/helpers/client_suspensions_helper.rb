module ClientSuspensionsHelper
  # 「6/20〜6/28」/ 終了日なしは「6/20〜（継続中）」
  def suspension_period_label(suspension)
    start = suspension.start_date.strftime("%-m/%-d")
    suspension.end_date ? "#{start}〜#{suspension.end_date.strftime("%-m/%-d")}" : "#{start}〜（継続中）"
  end

  # 今日を基準に 休止中 / 予定 / 終了 を色分け
  def suspension_state_badge(suspension)
    today = Date.current
    if suspension.covers?(today)
      tag.span("休止中", class: "status-badge st-suspended")
    elsif suspension.start_date > today
      tag.span("予定", class: "status-badge st-hospitalized")
    else
      tag.span("終了", class: "status-badge st-ended")
    end
  end
end
