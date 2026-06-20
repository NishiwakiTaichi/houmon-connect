class ScheduleChangesController < ApplicationController
  before_action :set_change, only: %i[show edit update confirm cancel]
  before_action :set_form_context, only: %i[new create edit update]
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
    # 振替担当の初期値は、その訪問の当初の担当スタッフ(多くは同じ担当が別日に振り替えるため)
    @change.new_user_id ||= @change.recurring_visit&.user_id
  end

  def create
    @change = ScheduleChange.new(change_params)
    @change.registered_by = current_user
    if @change.save
      ChatworkNotificationJob.perform_later("schedule_change_created", @change.id)
      saved_response("変更を登録しました（スケジュールへ即時反映されています）")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @change.update(change_params)
      saved_response("変更を更新しました")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 管理者の確認チェック(反映には影響しない「見た」という印)
  def confirm
    @change.confirm!(current_user)
    saved_response("変更を確認済みにしました")
  end

  # 取り消し(物理削除せず canceled_at を記録)
  def cancel
    @change.cancel_change!(current_user)
    ChatworkNotificationJob.perform_later("schedule_change_canceled", @change.id)
    saved_response("変更を取り消しました（記録は残ります）")
  end

  private

  def set_change
    @change = ScheduleChange.find(params[:id])
  end

  # フォーム/モーダルが持ち回る表示コンテキスト(差し替え対象の週・タブ)
  def set_form_context
    @service = params[:service].presence_in(%w[nursing rehab])
    @week = params[:week]
    @mine = params[:mine]
  end

  def require_manager
    return if current_user.manager?

    redirect_to root_path, alert: "確認チェックは管理者のみ行えます"
  end

  # 成功時: Turbo Streamでスケジュール・パネル・バッジ・一覧行をその場更新(モーダルは閉じる)。
  # 非Turboのときは表示中の週へリダイレクト。
  def saved_response(notice)
    @notice = notice
    build_schedule_context
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to schedules_path(service: @service, week: @week_start, mine: (@mine ? 1 : nil)), notice: notice }
    end
  end

  # フォーム/リンクが持ち回った表示コンテキストから、差し替え用のスケジュールを組み直す
  def build_schedule_context
    @service = params[:service].presence_in(%w[nursing rehab]) || @change.recurring_visit.service_type
    @mine = params[:mine] == "1"
    @week_start = parse_week(params[:week])
    @schedule = WeeklyScheduleBuilder.new(
      week_start: @week_start, service_type: @service, only_user: (@mine ? current_user : nil)
    )
  end

  def change_params
    params.require(:schedule_change).permit(
      :recurring_visit_id, :change_type, :target_date,
      :new_date, :new_start_time, :new_end_time, :new_user_id,
      :reason, :reason_detail, :cm_contact
    )
  end
end
