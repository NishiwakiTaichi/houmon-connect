class ScheduleChangesController < ApplicationController
  before_action :set_change, only: %i[show edit update confirm cancel]
  before_action :require_manager, only: :confirm

  def index
    @changes = ScheduleChange.includes(
      :registered_by, :new_user, :confirmed_by, recurring_visit: %i[client user]
    ).recent_first
  end

  def show
  end

  def new
    @change = ScheduleChange.new(recurring_visit_id: params[:recurring_visit_id], target_date: params[:date])
  end

  def create
    @change = ScheduleChange.new(change_params)
    @change.registered_by = current_user
    if @change.save
      redirect_to schedule_path_for(@change), notice: "変更を登録しました(スケジュールへ即時反映されています)"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @change.update(change_params)
      redirect_to schedule_path_for(@change), notice: "変更を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 管理者の確認チェック(反映には影響しない「見た」という印)
  def confirm
    @change.confirm!(current_user)
    redirect_back fallback_location: schedule_changes_path, notice: "変更を確認済みにしました"
  end

  # 取り消し(物理削除せず canceled_at を記録)
  def cancel
    @change.cancel_change!(current_user)
    redirect_back fallback_location: schedule_changes_path, notice: "変更を取り消しました(記録は残ります)"
  end

  private

  def set_change
    @change = ScheduleChange.find(params[:id])
  end

  def require_manager
    return if current_user.manager?

    redirect_to root_path, alert: "確認チェックは管理者のみ行えます"
  end

  # 即時反映が見えるよう、対象の区分・対象日の週へ戻す
  def schedule_path_for(change)
    schedules_path(service: change.recurring_visit.service_type, week: change.target_date)
  end

  def change_params
    params.require(:schedule_change).permit(
      :recurring_visit_id, :change_type, :target_date,
      :new_date, :new_start_time, :new_end_time, :new_user_id,
      :reason, :reason_detail, :cm_contact
    )
  end
end
