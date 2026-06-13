class RecurringVisitsController < ApplicationController
  before_action :set_recurring_visit, only: %i[edit update discard]

  def index
    @recurring_visits = RecurringVisit.kept.includes(:client, :user).in_week_order
    @service = params[:service].presence_in(%w[nursing rehab])
    @recurring_visits = @recurring_visits.where(service_type: @service) if @service
  end

  def new
    @recurring_visit = RecurringVisit.new
  end

  def create
    @recurring_visit = RecurringVisit.new(recurring_visit_params)
    if @recurring_visit.save
      redirect_to recurring_visits_path, notice: "#{@recurring_visit.client.name}さんの基本ルートを登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @recurring_visit.update(recurring_visit_params)
      redirect_to recurring_visits_path, notice: "#{@recurring_visit.client.name}さんの基本ルートを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
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
