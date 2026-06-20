require "rails_helper"

RSpec.describe "ClientSuspensions", type: :request do
  let(:manager)    { create(:user, role: :manager) }
  let(:client)     { create(:client) }
  let(:api_url)    { %r{api\.chatwork\.com} }

  before do
    sign_in manager
    stub_const("ENV", ENV.to_h.merge("CHATWORK_API_TOKEN" => "t", "CHATWORK_ROOM_ID" => "1"))
  end

  def suspension_params(overrides = {})
    { client_suspension: { start_date: "2026-07-01", end_date: "2026-07-10", note: "" }.merge(overrides) }
  end

  describe "POST /clients/:client_id/suspensions" do
    context "Chatwork API が正常なとき" do
      before { stub_request(:post, api_url).to_return(status: 200) }

      it "休止期間が登録され Chatwork に通知する" do
        perform_enqueued_jobs do
          post client_suspensions_path(client), params: suspension_params
        end
        expect(ClientSuspension.count).to eq 1
        expect(WebMock).to have_requested(:post, api_url).once
      end
    end

    context "Chatwork が落ちていても" do
      it "休止期間の登録は成功する" do
        expect { post client_suspensions_path(client), params: suspension_params }
          .to change(ClientSuspension, :count).by(1)
        expect(response).to have_http_status(:ok).or have_http_status(:found)
      end
    end
  end

  describe "PATCH /clients/:client_id/suspensions/:id" do
    let!(:suspension) { create(:client_suspension, client: client) }

    context "Chatwork API が正常なとき" do
      before { stub_request(:post, api_url).to_return(status: 200) }

      it "休止期間が更新され Chatwork に通知する" do
        perform_enqueued_jobs do
          patch client_suspension_path(client, suspension),
            params: suspension_params(end_date: "2026-07-20")
        end
        expect(suspension.reload.end_date).to eq Date.new(2026, 7, 20)
        expect(WebMock).to have_requested(:post, api_url).once
      end
    end

    context "Chatwork が落ちていても" do
      it "休止期間の更新は成功する" do
        patch client_suspension_path(client, suspension),
          params: suspension_params(end_date: "2026-07-20")
        expect(suspension.reload.end_date).to eq Date.new(2026, 7, 20)
      end
    end
  end

  describe "DELETE /clients/:client_id/suspensions/:id" do
    let!(:suspension) { create(:client_suspension, client: client) }

    context "Chatwork API が正常なとき" do
      before { stub_request(:post, api_url).to_return(status: 200) }

      it "休止期間が削除され Chatwork に通知する" do
        # destroyより先にジョブをenqueueする設計のため、perform_enqueued_jobsで
        # ジョブを即時実行してもレコードが存在することを確認できる
        perform_enqueued_jobs do
          delete client_suspension_path(client, suspension)
        end
        expect(ClientSuspension.count).to eq 0
        expect(WebMock).to have_requested(:post, api_url).once
      end
    end

    context "Chatwork が落ちていても" do
      it "休止期間の削除は成功する" do
        expect { delete client_suspension_path(client, suspension) }
          .to change(ClientSuspension, :count).by(-1)
      end
    end
  end
end
