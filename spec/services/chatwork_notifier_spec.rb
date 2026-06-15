require "rails_helper"

RSpec.describe ChatworkNotifier do
  let(:token)   { "test_api_token" }
  let(:room_id) { "99999" }
  let(:api_url) { "https://api.chatwork.com/v2/rooms/#{room_id}/messages" }

  before do
    stub_const("ENV", ENV.to_h.merge(
      "CHATWORK_API_TOKEN" => token,
      "CHATWORK_ROOM_ID"  => room_id
    ))
  end

  # POST 本文(URLエンコード)から "body" パラメーターを取り出す
  def chatwork_body
    req = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first
    URI.decode_www_form(req.body).to_h["body"]
  end

  describe ".schedule_change_created" do
    subject(:notify) { described_class.schedule_change_created(change) }

    context "休みの変更(cancel)" do
      let(:change) { create(:schedule_change, cm_contact: :not_contacted) }

      before { stub_request(:post, api_url).to_return(status: 200, body: '{"message_id":"1"}') }

      it "正しいURLにPOSTする" do
        notify
        expect(WebMock).to have_requested(:post, api_url)
      end

      it "x-chatworktoken ヘッダーを送る" do
        notify
        expect(WebMock).to have_requested(:post, api_url)
          .with(headers: { "x-chatworktoken" => token })
      end

      it "本文に利用者名が含まれる" do
        notify
        expect(chatwork_body).to include(change.recurring_visit.client.name)
      end

      it "本文に対象日が含まれる" do
        notify
        expect(chatwork_body).to include("6/16")
      end

      it "ケアマネ未連絡のとき ⚠ が含まれる" do
        notify
        expect(chatwork_body).to include("⚠")
      end

      it "登録者名が含まれる" do
        notify
        expect(chatwork_body).to include(change.registered_by.name)
      end

      it "[info][title] 装飾が含まれる" do
        notify
        expect(chatwork_body).to include("[info][title]").and include("[/info]")
      end
    end

    context "振替の変更(reschedule)" do
      let(:change) { create(:schedule_change, :reschedule, cm_contact: :contacted) }

      before { stub_request(:post, api_url).to_return(status: 200, body: '{"message_id":"2"}') }

      it "振替先日時が本文に含まれる" do
        notify
        expect(chatwork_body).to include("6/17").and include("11:00")
      end

      it "ケアマネ連絡済みのとき ⚠ が含まれない" do
        notify
        expect(chatwork_body).not_to include("⚠")
      end
    end

    context "API が 500 を返したとき" do
      let(:change) { create(:schedule_change) }

      before { stub_request(:post, api_url).to_return(status: 500) }

      it "例外を発生させない" do
        expect { notify }.not_to raise_error
      end
    end

    context "接続エラーのとき" do
      let(:change) { create(:schedule_change) }

      before do
        stub_request(:post, api_url).to_raise(Faraday::ConnectionFailed.new("connection refused"))
      end

      it "例外を発生させない" do
        expect { notify }.not_to raise_error
      end

      it "エラーをログに記録する" do
        allow(Rails.logger).to receive(:error)
        notify
        expect(Rails.logger).to have_received(:error).with(/ChatworkNotifier/)
      end
    end
  end
end
