module SchedulesHelper
  # コマ内を午前(開始が12:00より前)/午後に分ける
  def split_am_pm(visits)
    visits.partition { |visit| visit.start_time.hour < 12 }
  end

  # 訪問チップ(VisitCell)と時間休(StaffAbsence hourly)を start_time 昇順で混在させる
  def interleave_items(visits, hourly_absences)
    (visits + hourly_absences).sort_by(&:start_time)
  end

  # 振替先の表示「6/17 11:00(西脇)」
  def reschedule_target_label(change)
    "#{change.new_date.strftime("%-m/%-d")} #{change.new_start_time.strftime("%-H:%M")}（#{change.new_user.name}）"
  end

  # 振替元の表示「火 10:00(山田)」
  def reschedule_origin_label(change)
    rv = change.recurring_visit
    "#{wday_name(rv.wday)} #{rv.start_time.strftime("%-H:%M")}（#{rv.user.name}）"
  end
end
