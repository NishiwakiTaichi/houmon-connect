require "rails_helper"

RSpec.describe "ScheduleChanges", type: :request do
  let(:manager)  { create(:user, role: :manager) }
  let(:rv)       { create(:recurring_visit) }
  let(:api_url)  { %r{api\.chatwork\.com} }

  before do
    sign_in manager
    stub_const("ENV", ENV.to_h.merge("CHATWORK_API_TOKEN" => "t", "CHATWORK_ROOM_ID" => "1"))
  end

  def valid_create_params(overrides = {})
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

      it "変更が登録され Chatwork に1回 POST する" do
        post schedule_changes_path, params: valid_create_params
        expect(ScheduleChange.count).to eq 1
        expect(WebMock).to have_requested(:post, api_url).once
      end
    end

    context "Chatwork が落ちていても" do
      before { stub_request(:post, api_url).to_raise(Faraday::TimeoutError) }

      it "変更の登録は成功する" do
        expect { post schedule_changes_path, params: valid_create_params }
          .to change(ScheduleChange, :count).by(1)
        expect(response).to have_http_status(:ok).or have_http_status(:found)
      end
    end

    context "バリデーションエラーのとき" do
      before { stub_request(:post, api_url).to_return(status: 200) }

      it "理由が未選択なら登録されず Chatwork にも送信しない" do
        expect { post schedule_changes_path, params: valid_create_params(reason: "") }
          .not_to change(ScheduleChange, :count)
        expect(WebMock).not_to have_requested(:post, api_url)
      end
    end
  end

  describe "PATCH /schedule_changes/:id/cancel" do
    let!(:change) { create(:schedule_change, recurring_visit: rv) }

    context "Chatwork API が正常なとき" do
      before { stub_request(:post, api_url).to_return(status: 200) }

      it "変更が取り消され Chatwork に通知する" do
        patch cancel_schedule_change_path(change)
        expect(change.reload).to be_canceled
        expect(WebMock).to have_requested(:post, api_url).once
      end
    end

    context "Chatwork が落ちていても" do
      before { stub_request(:post, api_url).to_raise(Faraday::TimeoutError) }

      it "変更の取り消しは成功する" do
        patch cancel_schedule_change_path(change)
        expect(change.reload).to be_canceled
      end
    end
  end
end
