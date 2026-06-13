class SchedulesController < ApplicationController
  def index
    @service = params[:service].presence_in(%w[nursing rehab]) || default_service
    @week_start = parse_week
    @mine = params[:mine] == "1"
    @schedule = WeeklyScheduleBuilder.new(
      week_start: @week_start,
      service_type: @service,
      only_user: (@mine ? current_user : nil)
    )
  end

  private

  # ログイン直後は自分の職種に応じたタブを開く(設計書 5章)
  def default_service
    current_user.nurse? ? "nursing" : "rehab"
  end

  def parse_week
    date = params[:week].present? ? Date.parse(params[:week]) : Date.current
    date.beginning_of_week
  rescue Date::Error
    Date.current.beginning_of_week
  end
end
