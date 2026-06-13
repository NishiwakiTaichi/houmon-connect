require "rails_helper"

# モーダル経由でもサーバ側の挙動(スタッフ重複の禁止 / 利用者重複の確認)が
# これまでと変わらないことを担保する。
RSpec.describe "RecurringVisits", type: :request do
  let(:client) { create(:client) }
  let(:pt) { create(:user, job: :pt) }

  before { sign_in create(:user, role: :manager, job: :pt) }

  def valid_params(overrides = {})
    {
      recurring_visit: {
        client_id: client.id, user_id: pt.id, wday: 2,
        start_time: "10:00", end_time: "10:40", frequency: "weekly"
      }.merge(overrides.fetch(:recurring_visit, {})),
      service: "rehab"
    }.merge(overrides.except(:recurring_visit))
  end

  describe "POST /recurring_visits" do
    context "通常の登録" do
      it "新しい基本ルートが作られる" do
        expect { post recurring_visits_path, params: valid_params }
          .to change(RecurringVisit, :count).by(1)
      end
    end

    context "(2-a) スタッフの時間被り" do
      before do
        create(:recurring_visit, user: pt, client: create(:client), wday: 2, start_time: "10:00", end_time: "10:40")
      end

      it "登録を弾き、件数は変わらない" do
        expect {
          post recurring_visits_path, params: valid_params(recurring_visit: { start_time: "10:20", end_time: "11:00" })
        }.not_to change(RecurringVisit, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("様の訪問が入っています")
      end
    end

    context "(2-b) 利用者の時間被り" do
      let(:other_staff) { create(:user, job: :ot) }
      before do
        # 同じ利用者・同じ時間に別スタッフの訪問が既にある
        create(:recurring_visit, user: other_staff, client: client, wday: 2, start_time: "10:00", end_time: "10:40")
      end

      it "未承認では止まり、確認メッセージを表示する" do
        expect {
          post recurring_visits_path, params: valid_params
        }.not_to change(RecurringVisit, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("複数スタッフでの同時介入として、このまま登録を続けますか")
      end

      it "承認すると登録される" do
        expect {
          post recurring_visits_path, params: valid_params(acknowledge_client_overlap: "1")
        }.to change(RecurringVisit, :count).by(1)
      end
    end
  end

  describe "PATCH /recurring_visits/:id" do
    let!(:visit) { create(:recurring_visit, user: pt, client: client, wday: 2, start_time: "9:00", end_time: "9:40") }

    it "編集が保存される" do
      patch recurring_visit_path(visit), params: valid_params(recurring_visit: { start_time: "9:30", end_time: "10:10" })
      expect(visit.reload.start_time.strftime("%H:%M")).to eq "09:30"
    end

    it "スタッフ重複になる編集は弾く" do
      create(:recurring_visit, user: pt, client: create(:client), wday: 2, start_time: "14:00", end_time: "14:40")
      patch recurring_visit_path(visit), params: valid_params(recurring_visit: { start_time: "14:10", end_time: "14:50" })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(visit.reload.start_time.strftime("%H:%M")).to eq "09:00"
    end
  end

  describe "PATCH /recurring_visits/:id/discard(論理削除)" do
    let!(:visit) { create(:recurring_visit, user: pt, client: client) }

    it "keptから外れるが物理削除はされない" do
      expect {
        patch discard_recurring_visit_path(visit), params: { service: "rehab" }
      }.to change { RecurringVisit.kept.count }.by(-1)
      expect(RecurringVisit.count).to eq 1 # 物理削除されていない
      expect(visit.reload).to be_discarded
    end
  end

  describe "GET /recurring_visits/new(増回)" do
    it "client_idを渡すと利用者が選択済みになる" do
      get new_recurring_visit_path(client_id: client.id, service: "rehab")
      expect(response.body).to match(/selected="selected" value="#{client.id}"/)
    end
  end
end
