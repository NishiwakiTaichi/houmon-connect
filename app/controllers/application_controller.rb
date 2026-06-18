class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_current_user

  private

  # Loggableが記録者として参照する操作ユーザーを保持する
  def set_current_user
    Current.user = current_user
  end

  def parse_week(str)
    str.present? ? Date.parse(str).beginning_of_week : Date.current.beginning_of_week
  rescue Date::Error
    Date.current.beginning_of_week
  end
end
