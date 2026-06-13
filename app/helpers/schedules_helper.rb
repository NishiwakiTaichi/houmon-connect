module SchedulesHelper
  # コマ内を午前(開始が12:00より前)/午後に分ける
  def split_am_pm(visits)
    visits.partition { |visit| visit.start_time.hour < 12 }
  end
end
