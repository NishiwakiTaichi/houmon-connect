# 週間スケジュールはテーブルに保存せず、表示のたびに基本ルート+変更から合成する(設計書 3章)。
# 保存しないことで「基本ルートと週間表の二重管理」を避ける。
class WeeklyScheduleBuilder
  # 1コマの表示単位。状態に応じてビューが色分けする。
  #   state: :normal(白) / :cancel(グレー打ち消し) / :reschedule(緑・振替先)
  #   change: 紐づくScheduleChange(あれば)。未確認なら黄枠+⚠で表示する。
  VisitCell = Struct.new(
    :client, :start_time, :end_time, :recurring_visit, :state, :change,
    keyword_init: true
  ) do
    def normal? = state == :normal
    def canceled? = state == :cancel
    def rescheduled? = state == :reschedule
    def unconfirmed? = change.present? && !change.confirmed?
  end

  attr_reader :week_start, :days, :service_type

  def initialize(week_start:, service_type:, only_user: nil)
    @week_start = week_start
    @days = (week_start..week_start + 6).to_a # 月〜日
    @service_type = service_type.to_s
    @only_user = only_user
  end

  # スタッフごとの行データ
  # => [ { user: User, cells: { Date => [VisitCell(時刻順)] } }, ... ]
  def rows
    @rows ||= staff_members.map do |staff|
      cells = days.index_with { |date| cells_for(staff, date) }
      { user: staff, cells: cells }
    end
  end

  # 今週の変更一覧パネル用: この週に効いている有効な変更(対象日が今週、または振替先が今週)
  def changes_this_week
    @changes_this_week ||= effective_changes
      .select { |c| days.include?(c.target_date) || (c.reschedule? && c.new_date && days.include?(c.new_date)) }
      .sort_by(&:target_date)
  end

  def unconfirmed_count
    changes_this_week.count { |c| !c.confirmed? }
  end

  # その日のスタッフの休暇一覧(グリッドのセル描画用)
  def absences_for(user, date)
    absences_by_user_date[[ user.id, date ]] || []
  end

  private

  def cells_for(staff, date)
    entries = []

    # 1) 基本ルート由来のコマ(休み・振替元はここで打ち消し表示にする)
    (base_visits_by_user[staff.id] || []).each do |route|
      next unless route.visit_on?(date)
      next if route.client.suspended_on?(date) # その日が休止期間内なら非表示

      change = cell_change_for(route.id, date)
      state = change&.reschedule? || change&.cancel? ? :cancel : :normal
      entries << VisitCell.new(
        client: route.client, start_time: route.start_time, end_time: route.end_time,
        recurring_visit: route, state: state, change: change
      )
    end

    # 2) 振替先としてこのスタッフ・この日に入るコマ(緑)
    reschedule_targets.fetch([ staff.id, date ], []).each do |change|
      route = change.recurring_visit
      next if route.client.suspended_on?(change.new_date) # 休止期間内への振替先は非表示

      entries << VisitCell.new(
        client: route.client, start_time: change.new_start_time, end_time: change.new_end_time,
        recurring_visit: route, state: :reschedule, change: change
      )
    end

    entries.sort_by(&:start_time)
  end

  # 表示対象スタッフ: 基本ルートを持つ在籍者 + 振替先として今週入る在籍者
  def staff_members
    ids = base_visits_by_user.keys | reschedule_targets.keys.map(&:first)
    scope = User.where(active: true, id: ids).order(:id)
    scope = scope.where(id: @only_user.id) if @only_user
    scope
  end

  # 有効なルート(論理削除されておらず、契約が継続中=終了でない)をスタッフごとにまとめる。
  # その日に休止期間内かどうかは cells_for で日付ごとに判定する。
  def base_visits_by_user
    @base_visits_by_user ||= RecurringVisit.kept
      .where(service_type: service_type)
      .joins(:client).merge(Client.active)
      .includes(:user, client: :client_suspensions)
      .group_by(&:user_id)
  end

  # この区分の有効な変更(取り消されていない)を読み込む
  def effective_changes
    @effective_changes ||= ScheduleChange.effective
      .joins(:recurring_visit).where(recurring_visits: { service_type: service_type })
      .includes(:new_user, :confirmed_by, recurring_visit: [ :client, :user ])
      .to_a
  end

  # [recurring_visit_id, date] => 当日に効く休み/振替(最新のもの)
  def changes_by_route_date
    @changes_by_route_date ||= effective_changes
      .select { |c| c.cancel? || c.reschedule? }
      .group_by { |c| [ c.recurring_visit_id, c.target_date ] }
  end

  def cell_change_for(route_id, date)
    (changes_by_route_date[[ route_id, date ]] || []).max_by(&:created_at)
  end

  # [user_id, date] => その日の休暇一覧
  def absences_by_user_date
    @absences_by_user_date ||= StaffAbsence
      .where(date: days)
      .group_by { |a| [ a.user_id, a.date ] }
  end

  # [new_user_id, new_date] => 振替先の変更一覧
  def reschedule_targets
    @reschedule_targets ||= effective_changes
      .select { |c| c.reschedule? && c.new_user_id && c.new_date }
      .group_by { |c| [ c.new_user_id, c.new_date ] }
  end
end
