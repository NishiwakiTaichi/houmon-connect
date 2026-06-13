class RecurringVisitsController < ApplicationController
  before_action :set_recurring_visit, only: %i[edit update discard]

  def index
    @recurring_visits = RecurringVisit.kept.includes(:client, :user).in_week_order
    @service = params[:service].presence_in(%w[nursing rehab])
    @recurring_visits = @recurring_visits.where(service_type: @service) if @service
  end

  def new
    @recurring_visit = RecurringVisit.new(prefill_params)
    @planning_grid = RoutePlanningGrid.new
  end

  def create
    @recurring_visit = RecurringVisit.new(recurring_visit_params)

    if @recurring_visit.invalid?
      return render_new(status: :unprocessable_entity)
    end

    # (2-b) 利用者の時間被りは禁止しないが、未承認なら確認を促して一旦止める
    if unacknowledged_client_overlap?
      @confirm_client_overlap = true
      return render_new(status: :unprocessable_entity)
    end

    @recurring_visit.save!
    redirect_to recurring_visits_path, notice: "#{@recurring_visit.client.name}さんの基本ルートを登録しました"
  end

  def edit
  end

  def update
    @recurring_visit.assign_attributes(recurring_visit_params)

    if @recurring_visit.invalid?
      return render :edit, status: :unprocessable_entity
    end

    if unacknowledged_client_overlap?
      @confirm_client_overlap = true
      return render :edit, status: :unprocessable_entity
    end

    @recurring_visit.save!
    redirect_to recurring_visits_path, notice: "#{@recurring_visit.client.name}さんの基本ルートを更新しました"
  end

  # 物理削除はせず、discarded_atを記録してスケジュールから外す
  def discard
    @recurring_visit.discard!
    redirect_to recurring_visits_path, notice: "#{@recurring_visit.client.name}さんの基本ルートを削除しました(記録は残ります)"
  end

  private

  def set_recurring_visit
    @recurring_visit = RecurringVisit.kept.find(params[:id])
  end

  def render_new(status:)
    @planning_grid = RoutePlanningGrid.new
    render :new, status: status
  end

  # 「重複を承知で登録する」にチェックが無く、かつ利用者の時間被りがあるとき true
  def unacknowledged_client_overlap?
    params[:acknowledge_client_overlap].blank? && @recurring_visit.client_conflicts.any?
  end

  # 空き枠ビューからの遷移で、担当・曜日・開始時刻を初期入力する
  def prefill_params
    start = params[:start_time].presence
    started_at = start && Time.zone.parse(start)
    {
      user_id: params[:user_id].presence,
      wday: params[:wday].presence,
      start_time: started_at,
      end_time: started_at && started_at + RoutePlanningGrid::SLOT_MINUTES.minutes
    }
  end

  def recurring_visit_params
    # service_type は受け取らない(担当スタッフの職種からモデル側で自動設定)
    permitted = params.require(:recurring_visit).permit(
      :client_id, :user_id, :wday, :start_time, :end_time,
      :frequency, :anchor_date, visit_weeks: []
    )
    # 第n週のチェックボックス配列を "2,4" 形式の文字列に変換する
    permitted[:visit_weeks] = Array(permitted[:visit_weeks]).reject(&:blank?).join(",")
    permitted
  end
end
