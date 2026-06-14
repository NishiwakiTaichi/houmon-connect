class ActivityLogsController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @logs = ActivityLog.includes(:user, :target).recent_first
    @logs = @logs.for_client_name(@query) if @query.present?
    @logs = @logs.page(params[:page]).per(50)
  end
end
