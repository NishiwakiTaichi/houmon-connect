class StaffAbsencesController < ApplicationController
  before_action :set_absence, only: :destroy
  before_action :authorize_absence!, only: :destroy

  def index
    @week_start = parse_week
    week_range  = @week_start..(@week_start + 6)

    @absences = StaffAbsence
      .where(date: week_range)
      .includes(:user)
      .order(:date, :absence_type)
  end

  def new
    @absence = StaffAbsence.new(user_id: current_user.id)
    @users   = selectable_users
  end

  def create
    @absence = StaffAbsence.new(absence_params)
    @absence.user = current_user unless current_user.manager?

    if @absence.save
      respond_to do |format|
        format.turbo_stream do
          @week_start = @absence.date.beginning_of_week
          render turbo_stream: [
            turbo_stream.prepend("absences_list", partial: "staff_absences/absence",
                                                  locals: { absence: @absence }),
            turbo_stream.update("flash",
                                partial: "layouts/flash_message",
                                locals: { notice: "休暇を登録しました" })
          ]
        end
        format.html { redirect_to staff_absences_path(week: @absence.date), notice: "休暇を登録しました" }
      end
    else
      @users = selectable_users
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @absence.destroy!
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("absence-#{@absence.id}"),
          turbo_stream.update("flash",
                              partial: "layouts/flash_message",
                              locals: { notice: "休暇を削除しました" })
        ]
      end
      format.html { redirect_to staff_absences_path, notice: "休暇を削除しました" }
    end
  end

  private

  def set_absence
    @absence = StaffAbsence.find(params[:id])
  end

  def authorize_absence!
    return if current_user.manager? || @absence.user_id == current_user.id

    redirect_to staff_absences_path, alert: "自分の休暇のみ削除できます"
  end

  def absence_params
    params.require(:staff_absence).permit(:user_id, :date, :absence_type, :start_time, :end_time, :note)
  end

  def selectable_users
    current_user.manager? ? User.where(active: true).order(:name) : User.where(id: current_user.id)
  end

  def parse_week
    date = params[:week].present? ? Date.parse(params[:week]) : Date.current
    date.beginning_of_week
  rescue Date::Error
    Date.current.beginning_of_week
  end
end
