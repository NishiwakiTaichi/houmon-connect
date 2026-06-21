class GuestSessionsController < ApplicationController
  skip_before_action :authenticate_user!

  ALLOWED_ROLES = %w[manager staff].freeze

  def create
    role = params[:role].presence_in(ALLOWED_ROLES)
    unless role
      redirect_to new_user_session_path, alert: "不正なリクエストです"
      return
    end

    user = User.find_by(role: role, demo: true)
    unless user
      redirect_to new_user_session_path, alert: "ゲストアカウントが見つかりません"
      return
    end

    sign_in user
    redirect_to root_path, notice: "ゲスト(#{user.role == 'manager' ? '管理者' : '一般スタッフ'})としてログインしました"
  end
end
