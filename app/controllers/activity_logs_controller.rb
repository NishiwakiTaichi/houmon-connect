class ActivityLogsController < ApplicationController
  def index
    @logs = ActivityLog.includes(:user).recent_first.limit(200)
  end
end
