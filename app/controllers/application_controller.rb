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

  # デモユーザーの操作なら通知をスキップ。Chatwork API エラーはログに残して続行する。
  def notify_chatwork
    return if current_user&.demo?
    yield
  rescue Faraday::Error => e
    Rails.logger.error("[ChatworkNotifier] 通知失敗(続行): #{e.class} #{e.message}")
  end
end
