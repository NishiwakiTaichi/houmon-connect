class ActivityLogsController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    # :target はポリモーフィックなので preload(別クエリ)。:client は JOIN と共存できる includes。
    @logs = ActivityLog.includes(:user, :client).preload(:target).recent_first
    @logs = @logs.for_client_name(@query) if @query.present?
    @logs = @logs.page(params[:page]).per(50)
  end
end
