# 基本ルート管理画面の「空き枠が見える」表を組み立てる(スタッフ×曜日)。
# 看護/リハの区分(=担当スタッフの職種)で対象スタッフを絞り込む。
# 将来の「新規利用者の受け入れ調整」機能の土台。
class RoutePlanningGrid
  WDAYS = [ 1, 2, 3, 4, 5, 6, 0 ].freeze # 月〜日
  STANDARD_SLOTS = %w[9:00 10:00 11:00 13:30 14:30 15:30].freeze
  SLOT_MINUTES = 40
  # サービス区分ごとの職種(看護=看護師、リハ=PT/OT/ST)
  JOBS_BY_SERVICE = { "nursing" => [ :nurse ], "rehab" => [ :pt, :ot, :st ] }.freeze

  Cell = Struct.new(:visits, :free_slots)

  attr_reader :staff, :service_type

  def initialize(service_type:)
    @service_type = service_type.to_s
    @staff = User.where(active: true, job: JOBS_BY_SERVICE.fetch(@service_type, [])).order(:id).to_a
    @visits_by_user = RecurringVisit.kept.where(service_type: @service_type)
      .includes(:client).group_by(&:user_id)
  end

  def cell(user, wday)
    day_visits = (@visits_by_user[user.id] || [])
      .select { |visit| visit.wday == wday }
      .sort_by(&:start_time)
    Cell.new(day_visits, free_standard_slots(day_visits))
  end

  private

  # 標準時間枠のうち、その日の既存ルートと重ならない(=空いている)ものだけを返す
  def free_standard_slots(day_visits)
    occupied = day_visits.map { |visit| [ seconds_of_day(visit.start_time), seconds_of_day(visit.end_time) ] }
    STANDARD_SLOTS.reject do |slot|
      start_sec = slot_seconds(slot)
      end_sec = start_sec + SLOT_MINUTES * 60
      occupied.any? { |vs, ve| start_sec < ve && vs < end_sec }
    end
  end

  def slot_seconds(slot)
    hour, min = slot.split(":").map(&:to_i)
    hour * 3600 + min * 60
  end

  # time型カラムは基準日が付くため、時刻部分だけを秒に変換して比較する
  def seconds_of_day(time)
    time.hour * 3600 + time.min * 60 + time.sec
  end
end
