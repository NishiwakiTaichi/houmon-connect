require "rails_helper"

RSpec.describe "ScheduleChanges", type: :request do
  let(:manager)  { create(:user, role: :manager) }
  let(:rv)       { create(:recurring_visit) }
  let(:api_url)  { %r{api\.chatwork\.com} }

  before { sign_in manager }

  def valid_params(overrides = {})
    {
      schedule_change: {
        recurring_visit_id: rv.id,
        change_type: "cancel",
        target_date: "2026-06-20",
        reason: "sick",
        cm_contact: "not_contacted"
      }.merge(overrides)
    }
  end

  describe "POST /schedule_changes" do
    context "Chatwork API が正常なとき" do
      before { stub_request(:post, api_url).to_return(status: 200, body: '{"message_id":"1"}') }

      it "変更が登録され、Chatwork に1回 POST する" do
        expect { post schedule_changes_path, params: valid_params }
          .to change(ScheduleChange, :count).by(1)
        expect(WebMock).to have_requested(:post, api_url).once
      end
    end

    context "Chatwork API が落ちているとき" do
      before { stub_request(:post, api_url).to_raise(Faraday::ConnectionFailed.new("timeout")) }

      it "変更の登録は成功する(通知失敗でロールバックしない)" do
        expect { post schedule_changes_path, params: valid_params }
          .to change(ScheduleChange, :count).by(1)
      end

      it "レスポンスは成功系(Turbo Stream または リダイレクト)" do
        post schedule_changes_path, params: valid_params
        expect(response).to have_http_status(:ok).or have_http_status(:found)
      end
    end

    context "バリデーションエラーのとき" do
      before { stub_request(:post, api_url).to_return(status: 200, body: '{"message_id":"1"}') }

      it "理由が未選択なら登録されず Chatwork にも送信しない" do
        expect { post schedule_changes_path, params: valid_params(reason: "") }
          .not_to change(ScheduleChange, :count)
        expect(WebMock).not_to have_requested(:post, api_url)
      end
    end
  end
end
