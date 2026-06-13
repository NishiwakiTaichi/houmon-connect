class ClientsController < ApplicationController
  before_action :set_client, only: %i[show edit update]

  def index
    @clients = Client.ordered_by_kana
  end

  def show
    # 基本ルートの逆引きは recurring_visits/_client_routes 部分テンプレートが描画する(課題6)
  end

  def new
    @client = Client.new
  end

  def create
    @client = Client.new(client_params)
    if @client.save
      redirect_to @client, notice: "利用者「#{@client.name}」さんを登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: "利用者「#{@client.name}」さんの情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :kana, :status, :newcomer_policy, :gender_restriction, :note)
  end
end
