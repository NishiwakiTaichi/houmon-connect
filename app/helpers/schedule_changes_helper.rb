module ScheduleChangesHelper
  # フォームの「対象の基本ルート」選択肢:「田中 太郎 ｜ 火 10:00-10:40(山田・リハ)」
  def recurring_visit_option_label(visit)
    "#{visit.client.name} ｜ #{wday_name(visit.wday)} #{visit_time_range(visit)}" \
      "（#{visit.user.name}・#{enum_t(visit, :service_type)}）"
  end

  # 一覧/パネルの「基本ルート(変更前)」表示
  def change_base_label(change)
    visit = change.recurring_visit
    "#{visit.client.name} ｜ #{wday_name(visit.wday)} #{visit_time_range(visit)}（#{visit.user.name}）"
  end

  # 変更内容の要約(種別ごと)
  def change_after_label(change)
    case change.change_type.to_sym
    when :cancel
      "#{change.target_date.strftime("%-m/%-d")} 休み"
    when :reschedule
      "#{change.target_date.strftime("%-m/%-d")} → #{reschedule_target_label(change)} に振替"
    when :suspend
      "#{change.target_date.strftime("%-m/%-d")} から休止"
    when :resume
      "#{change.target_date.strftime("%-m/%-d")} から再開"
    end
  end

  def cm_contact_badge(change)
    css = change.contacted? ? "cm-ok" : "cm-ng"
    text = change.contacted? ? "CM連絡済" : "CM未連絡 ⚠"
    tag.span(text, class: css)
  end

  # 確認状態のアイコン(✓確認済 / ⚠未確認 / ✗取り消し)
  def change_state_mark(change)
    if change.canceled?
      tag.span("✗", class: "state x", title: "取り消し済み")
    elsif change.confirmed?
      tag.span("✓", class: "state k", title: "確認済み")
    else
      tag.span("⚠", class: "state w", title: "未確認")
    end
  end
end
