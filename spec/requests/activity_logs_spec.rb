require "rails_helper"

RSpec.describe "ActivityLogs", type: :request do
  before { sign_in create(:user) }

  def with_operator
    Current.user = create(:user)
    yield
  ensure
    Current.reset
  end

  it "全スタッフが変更ログ一覧を閲覧できる" do
    with_operator { create(:client) }
    get activity_logs_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("変更ログ", "登録")
  end

  it "利用者名でログを絞り込める(本人・基本ルート・変更・休止期間を横断)" do
    tanaka = create(:client, name: "田中 太郎", kana: "たなか たろう")
    sato = create(:client, name: "佐藤 花子", kana: "さとう はなこ")
    with_operator do
      create(:recurring_visit, client: tanaka) # 田中の基本ルート → 田中に紐づくログ
      create(:client_suspension, client: sato)  # 佐藤の休止期間
    end

    get activity_logs_path(q: "田中")
    expect(response.body).to include("田中 太郎")
    expect(response.body).not_to include("佐藤 花子")
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
