module Admin
  class UsersController < ApplicationController
    before_action :require_manager
    before_action :set_user, only: %i[edit update]

    def index
      @users = User.order(:id)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: "スタッフ「#{@user.name}」さんを登録しました"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      # パスワード欄が空なら変更しない(他項目だけ更新する)
      attrs = user_params
      attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?

      if @user.update(attrs)
        redirect_to admin_users_path, notice: "スタッフ「#{@user.name}」さんの情報を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def require_manager
      return if current_user.manager?

      redirect_to root_path, alert: "この画面は管理者のみ利用できます"
    end

    def user_params
      params.require(:user).permit(:name, :kana, :email, :role, :job, :active, :password, :password_confirmation)
    end
  end
end
