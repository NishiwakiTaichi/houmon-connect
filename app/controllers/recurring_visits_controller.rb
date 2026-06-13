class RecurringVisitsController < ApplicationController
  before_action :set_recurring_visit, only: %i[edit update discard]

  def index
    @service = current_service
    @planning_grid = RoutePlanningGrid.new(service_type: @service)
  end

  def new
    @service = current_service
    @recurring_visit = RecurringVisit.new(prefill_params)
  end

  def create
    @service = current_service
    @recurring_visit = RecurringVisit.new(recurring_visit_params)

    if @recurring_visit.invalid?
      return render :new, status: :unprocessable_entity
    end

    # (2-b) 利用者の時間被りは禁止しないが、未承認なら確認を促して一旦止める
    if unacknowledged_client_overlap?
      @confirm_client_overlap = true
      return render :new, status: :unprocessable_entity
    end

    @recurring_visit.save!
    respond_to_saved("#{@recurring_visit.client.name}さんの基本ルートを登録しました")
  end

  def edit
    @service = current_service
  end

  def update
    @service = current_service
    @recurring_visit.assign_attributes(recurring_visit_params)

    if @recurring_visit.invalid?
      return render :edit, status: :unprocessable_entity
    end

    if unacknowledged_client_overlap?
      @confirm_client_overlap = true
      return render :edit, status: :unprocessable_entity
    end

    @recurring_visit.save!
    respond_to_saved("#{@recurring_visit.client.name}さんの基本ルートを更新しました")
  end

  # 物理削除はせず、discarded_atを記録してスケジュールから外す
  def discard
    @service = current_service
    @recurring_visit.discard!
    respond_to_saved("#{@recurring_visit.client.name}さんの基本ルートを削除しました(記録は残ります)")
  end

  private

  def set_recurring_visit
    @recurring_visit = RecurringVisit.kept.find(params[:id])
  end

  # 保存成功時: グリッド(と利用者詳細の逆引き)をその場で差し替え、モーダルを閉じる
  def respond_to_saved(notice)
    @planning_grid = RoutePlanningGrid.new(service_type: @service)
    @notice = notice
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to recurring_visits_path(service: @service), notice: notice }
    end
  end

  def current_service
    params[:service].presence_in(%w[nursing rehab]) || (current_user.nurse? ? "nursing" : "rehab")
  end

  # 「重複を承知で登録する」にチェックが無く、かつ利用者の時間被りがあるとき true
  def unacknowledged_client_overlap?
    params[:acknowledge_client_overlap].blank? && @recurring_visit.client_conflicts.any?
  end

  # 空き枠ビューからの遷移で担当・曜日・開始時刻を、
  # 「増回」からの遷移で利用者を、初期入力する
  def prefill_params
    start = params[:start_time].presence
    started_at = start && Time.zone.parse(start)
    {
      client_id: params[:client_id].presence,
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
