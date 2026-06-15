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
    user = current_user.manager? ? User.find(base_params[:user_id]) : current_user

    if base_params[:absence_type] == "hourly"
      create_hourly_batch(user)
    else
      @absence = StaffAbsence.new(base_params.merge(user: user))
      if @absence.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.prepend("absences_list", partial: "staff_absences/absence",
                                                    locals: { absence: @absence }),
              turbo_stream.update("flash", partial: "layouts/flash_message",
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

  def create_hourly_batch(user)
    raw_slots = params.dig(:staff_absence, :hourly_slots) || []
    slots = raw_slots.map { |s| s.permit(:start_time, :end_time) }
                     .reject { |s| s[:start_time].blank? && s[:end_time].blank? }

    if slots.empty?
      @absence = StaffAbsence.new(base_params.merge(user: user))
      @absence.errors.add(:base, "時間休の時刻を1件以上入力してください")
      @users = selectable_users
      return render :new, status: :unprocessable_entity
    end

    @absences_batch = slots.map do |slot|
      StaffAbsence.new(user: user, date: base_params[:date], absence_type: :hourly,
                       start_time: slot[:start_time], end_time: slot[:end_time],
                       note: base_params[:note])
    end

    all_valid = @absences_batch.all?(&:valid?)

    if all_valid && batch_has_overlap?(@absences_batch)
      @absences_batch.first.errors.add(:base, "入力した時間休の中に重複する時刻があります")
      all_valid = false
    end

    if all_valid
      StaffAbsence.transaction { @absences_batch.each(&:save!) }
      count = @absences_batch.size
      notice = count > 1 ? "#{count}件の時間休を登録しました" : "休暇を登録しました"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            *@absences_batch.reverse.map { |a|
              turbo_stream.prepend("absences_list", partial: "staff_absences/absence",
                                                    locals: { absence: a })
            },
            turbo_stream.update("flash", partial: "layouts/flash_message",
                                         locals: { notice: notice })
          ]
        end
        format.html { redirect_to staff_absences_path(week: @absences_batch.first.date), notice: notice }
      end
    else
      @absence = @absences_batch.first
      @users = selectable_users
      render :new, status: :unprocessable_entity
    end
  end

  def batch_has_overlap?(absences)
    absences.combination(2).any? do |a, b|
      a.start_time.present? && b.end_time.present? &&
        a.start_time < b.end_time && b.start_time < a.end_time
    end
  end

  def base_params
    params.require(:staff_absence).permit(:user_id, :date, :absence_type, :note)
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
