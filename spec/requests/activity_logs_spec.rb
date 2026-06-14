require "rails_helper"

RSpec.describe "ActivityLogs", type: :request do
  before { sign_in create(:user) }

  it "全スタッフが変更ログ一覧を閲覧できる" do
    Current.user = create(:user)
    create(:client) # createログが残る
    Current.reset

    get activity_logs_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("変更ログ")
    expect(response.body).to include("登録")
  end

  describe "改変不可(indexのみ)", type: :routing do
    it "create/update/destroy のルートが無い" do
      expect(get: "/activity_logs").to be_routable
      expect(post: "/activity_logs").not_to be_routable
      expect(patch: "/activity_logs/1").not_to be_routable
      expect(delete: "/activity_logs/1").not_to be_routable
    end
  end
end
