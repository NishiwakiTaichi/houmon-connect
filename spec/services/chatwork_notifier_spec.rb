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
    stub_request(:post, api_url).to_return(status: 200, body: '{"message_id":"1"}')
  end

  # POST 本文(URLエンコード)から body パラメーターを取り出す
  def chatwork_body
    req = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first
    URI.decode_www_form(req.body).to_h["body"]
  end

  # ── スケジュール変更 ──────────────────────────────────────────────────────

  describe ".schedule_change_created" do
    subject(:notify) { described_class.schedule_change_created(change) }

    context "休みの変更(cancel)" do
      let(:change) { create(:schedule_change, cm_contact: :not_contacted) }

      it "正しいURLにPOSTし x-chatworktoken ヘッダーを送る" do
        notify
        expect(WebMock).to have_requested(:post, api_url)
          .with(headers: { "x-chatworktoken" => token })
      end

      it "本文に利用者名・対象日・登録者が含まれる" do
        notify
        body = chatwork_body
        expect(body).to include(change.recurring_visit.client.name)
          .and include("6/16")
          .and include(change.registered_by.name)
      end

      it "ケアマネ未連絡のとき ⚠ が含まれる" do
        notify
        expect(chatwork_body).to include("⚠")
      end

      it "[info][title] 装飾が含まれる" do
        notify
        expect(chatwork_body).to include("[info][title]").and include("[/info]")
      end
    end

    context "振替の変更(reschedule)" do
      let(:change) { create(:schedule_change, :reschedule, cm_contact: :contacted) }

      it "振替先日時が本文に含まれ、連絡済みのとき ⚠ が含まれない" do
        notify
        body = chatwork_body
        expect(body).to include("6/17").and include("11:00")
        expect(body).not_to include("⚠")
      end
    end

    context "接続エラーのとき" do
      before { stub_request(:post, api_url).to_raise(Faraday::ConnectionFailed.new("refused")) }

      it "Faraday::Errorを発生させる(ジョブ側でretry_onによりリトライされる)" do
        expect { described_class.schedule_change_created(create(:schedule_change)) }
          .to raise_error(Faraday::ConnectionFailed)
      end
    end
  end

  describe ".schedule_change_canceled" do
    subject(:notify) { described_class.schedule_change_canceled(change) }

    let(:canceler) { create(:user) }
    let(:change) do
      c = create(:schedule_change, cm_contact: :not_contacted)
      c.cancel_change!(canceler)
      c
    end

    it "タイトルに「取り消し」が含まれる" do
      notify
      expect(chatwork_body).to include("取り消し")
    end

    it "本文に利用者名・取り消し者が含まれる" do
      notify
      body = chatwork_body
      expect(body).to include(change.recurring_visit.client.name)
        .and include(canceler.name)
    end

    it "ケアマネ未連絡のとき ⚠ が含まれる" do
      notify
      expect(chatwork_body).to include("⚠")
    end
  end

  # ── 休止期間 ─────────────────────────────────────────────────────────────

  describe ".suspension_created / .suspension_updated / .suspension_destroyed" do
    let(:operator)   { create(:user) }
    let(:suspension) { create(:client_suspension) }

    shared_examples "休止期間メッセージ" do |verb|
      it "タイトルに「#{verb}」が含まれる" do
        subject
        expect(chatwork_body).to include(verb)
      end

      it "本文に利用者名・期間・操作者が含まれる" do
        subject
        body = chatwork_body
        expect(body).to include(suspension.client.name)
          .and include("6/20")
          .and include(operator.name)
      end

      it "備考があれば含まれる" do
        subject
        expect(chatwork_body).to include(suspension.note)
      end
    end

    describe ".suspension_created" do
      subject { described_class.suspension_created(suspension, operator) }

      include_examples "休止期間メッセージ", "登録"
    end

    describe ".suspension_updated" do
      subject { described_class.suspension_updated(suspension, operator) }

      include_examples "休止期間メッセージ", "更新"
    end

    describe ".suspension_destroyed" do
      subject { described_class.suspension_destroyed(suspension, operator) }

      include_examples "休止期間メッセージ", "削除"
    end

    context "終了日が未定の場合" do
      let(:suspension) { create(:client_suspension, :open_ended) }

      it "「終了日未定」が含まれる" do
        described_class.suspension_created(suspension, operator)
        expect(chatwork_body).to include("終了日未定")
      end
    end
  end

  # ── 基本ルート ────────────────────────────────────────────────────────────

  describe ".recurring_visit_updated / .recurring_visit_discarded" do
    let(:operator) { create(:user) }
    let(:rv)       { create(:recurring_visit) }

    shared_examples "基本ルートメッセージ" do |verb|
      it "タイトルに「#{verb}」が含まれる" do
        subject
        expect(chatwork_body).to include(verb)
      end

      it "本文に利用者名・担当スタッフ・操作者が含まれる" do
        subject
        body = chatwork_body
        expect(body).to include(rv.client.name)
          .and include(rv.user.name)
          .and include(operator.name)
      end
    end

    describe ".recurring_visit_updated" do
      subject { described_class.recurring_visit_updated(rv, operator) }

      context "saved_changes が空(差分なし)" do
        before { allow(rv).to receive(:saved_changes).and_return({}) }

        include_examples "基本ルートメッセージ", "変更"

        it "→ 矢印は含まれない" do
          subject
          expect(chatwork_body).not_to include(" → ")
        end
      end

      context "曜日と時刻が変わった場合" do
        # wday: 2(火) → 4(木)、start_time: 10:00 → 14:00、end_time: 10:40 → 14:40
        before do
          allow(rv).to receive(:saved_changes).and_return(
            "wday"       => [ 2, 4 ],
            "start_time" => [ "2000-01-01T10:00:00.000+09:00", "2000-01-01T14:00:00.000+09:00" ],
            "end_time"   => [ "2000-01-01T10:40:00.000+09:00", "2000-01-01T14:40:00.000+09:00" ]
          )
        end

        it "変更前→変更後のルートが含まれる" do
          subject
          body = chatwork_body
          expect(body).to include("火").and include("木").and include("10:00").and include("14:00")
        end

        it "→ 矢印が含まれる" do
          subject
          expect(chatwork_body).to include(" → ")
        end
      end
    end

    describe ".recurring_visit_discarded" do
      subject { described_class.recurring_visit_discarded(rv, operator) }

      include_examples "基本ルートメッセージ", "削除"
    end
  end
end
