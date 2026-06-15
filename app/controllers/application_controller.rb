class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_current_user

  private

  # Loggableが記録者として参照する操作ユーザーを保持する
  def set_current_user
    Current.user = current_user
  end
end
