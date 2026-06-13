# 週間スケジュールはテーブルに保存せず、表示のたびに基本ルートから合成する(設計書 3章)。
# 保存しないことで「基本ルートと週間表の二重管理」を避ける。
class WeeklyScheduleBuilder
  attr_reader :week_start, :days, :service_type

  def initialize(week_start:, service_type:, only_user: nil)
    @week_start = week_start
    @days = (week_start..week_start + 6).to_a # 月〜日
    @service_type = service_type
    @only_user = only_user
  end

  # スタッフごとの行データ
  # => [ { user: User, cells: { Date => [RecurringVisit(時刻順)] } }, ... ]
  def rows
    @rows ||= staff_members.map do |staff|
      visits = visits_by_user.fetch(staff.id, [])
      cells = days.index_with do |date|
        visits.select { |visit| visit.visit_on?(date) }.sort_by(&:start_time)
      end
      { user: staff, cells: cells }
    end
  end

  private

  # この区分の有効なルートを持つ在籍スタッフ(「自分のみ表示」時は本人だけ)
  def staff_members
    staffs = User.where(active: true, id: visits_by_user.keys).order(:id)
    staffs = staffs.where(id: @only_user.id) if @only_user
    staffs
  end

  # 有効なルート(論理削除されておらず、利用者が利用中)をスタッフごとにまとめる
  def visits_by_user
    @visits_by_user ||= RecurringVisit.kept
      .where(service_type: service_type)
      .joins(:client).merge(Client.active)
      .includes(:client)
      .group_by(&:user_id)
  end
end
