class ClientSuspensionsController < ApplicationController
  before_action :set_client
  before_action :set_suspension, only: %i[edit update destroy]

  def new
    @suspension = @client.client_suspensions.build
  end

  def create
    @suspension = @client.client_suspensions.build(suspension_params)
    if @suspension.save
      notify_chatwork { ChatworkNotifier.suspension_created(@suspension, current_user) }
      saved_response("休止期間を追加しました")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @suspension.update(suspension_params)
      notify_chatwork { ChatworkNotifier.suspension_updated(@suspension, current_user) }
      saved_response("休止期間を更新しました")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # destroyより先に通知してレコードが存在する状態を保証する
    notify_chatwork { ChatworkNotifier.suspension_destroyed(@suspension, current_user) }
    @suspension.destroy
    saved_response("休止期間を削除しました")
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end

  def set_suspension
    @suspension = @client.client_suspensions.find(params[:id])
  end

  # 成功時: 休止期間一覧をその場で差し替え、モーダルを閉じる
  def saved_response(notice)
    @notice = notice
    respond_to do |format|
      format.turbo_stream
      # 非Turboのときは、操作元(利用者詳細 or 編集)へ戻す
      format.html { redirect_back fallback_location: edit_client_path(@client), notice: notice }
    end
  end

  def suspension_params
    params.require(:client_suspension).permit(:start_date, :end_date, :note)
  end
end
