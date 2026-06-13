# 基本ルート管理画面の表(スタッフ×曜日)を組み立てる。
# 看護/リハの区分(=担当スタッフの職種)で対象スタッフを絞り込む。
class RoutePlanningGrid
  WDAYS = [ 1, 2, 3, 4, 5, 6, 0 ].freeze # 月〜日
  # サービス区分ごとの職種(看護=看護師、リハ=PT/OT/ST)
  JOBS_BY_SERVICE = { "nursing" => [ :nurse ], "rehab" => [ :pt, :ot, :st ] }.freeze

  attr_reader :staff, :service_type

  def initialize(service_type:)
    @service_type = service_type.to_s
    @staff = User.where(active: true, job: JOBS_BY_SERVICE.fetch(@service_type, [])).order(:id).to_a
    @visits_by_user = RecurringVisit.kept.where(service_type: @service_type)
      .includes(:client).group_by(&:user_id)
  end

  # そのスタッフ・曜日の訪問を開始時刻順で返す
  def cell(user, wday)
    (@visits_by_user[user.id] || [])
      .select { |visit| visit.wday == wday }
      .sort_by(&:start_time)
  end
end
