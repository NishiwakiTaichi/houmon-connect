module Admin
  class UsersController < ApplicationController
    before_action :require_manager

    def index
      @users = User.order(:id)
    end

    private

    def require_manager
      return if current_user.manager?

      redirect_to root_path, alert: "この画面は管理者のみ利用できます"
    end
  end
end
