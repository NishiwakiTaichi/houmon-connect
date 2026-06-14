require "rails_helper"

RSpec.describe ClientSuspension, type: :model do
  describe "#covers?" do
    context "開始日と終了日が両方あるとき(6/20〜6/28)" do
      let(:suspension) { build(:client_suspension, start_date: Date.new(2026, 6, 20), end_date: Date.new(2026, 6, 28)) }

      it "期間内(開始日・中日・終了日)はtrue" do
        expect(suspension.covers?(Date.new(2026, 6, 20))).to be true # 開始日(境界)
        expect(suspension.covers?(Date.new(2026, 6, 24))).to be true # 中日
        expect(suspension.covers?(Date.new(2026, 6, 28))).to be true # 終了日(境界)
      end

      it "期間外(開始前・終了後)はfalse" do
        expect(suspension.covers?(Date.new(2026, 6, 19))).to be false # 開始前日
        expect(suspension.covers?(Date.new(2026, 6, 29))).to be false # 終了翌日(自動復活)
      end
    end

    context "終了日が空のとき(開始日以降ずっと休止)" do
      let(:suspension) { build(:client_suspension, :open_ended, start_date: Date.new(2026, 6, 20)) }

      it "開始日以降はずっとtrue、開始前はfalse" do
        expect(suspension.covers?(Date.new(2026, 6, 19))).to be false
        expect(suspension.covers?(Date.new(2026, 6, 20))).to be true
        expect(suspension.covers?(Date.new(2027, 1, 1))).to be true # 遠い未来でも休止のまま
      end
    end

    context "月をまたぐとき(6/25〜7/5)" do
      let(:suspension) { build(:client_suspension, start_date: Date.new(2026, 6, 25), end_date: Date.new(2026, 7, 5)) }

      it "月またぎでも期間内/外を正しく判定する" do
        expect(suspension.covers?(Date.new(2026, 6, 30))).to be true # 6月末
        expect(suspension.covers?(Date.new(2026, 7, 1))).to be true  # 7月頭
        expect(suspension.covers?(Date.new(2026, 7, 5))).to be true  # 終了日
        expect(suspension.covers?(Date.new(2026, 7, 6))).to be false # 終了後
      end
    end
  end

  describe "バリデーション" do
    it "開始日が無いと無効" do
      expect(build(:client_suspension, start_date: nil)).to be_invalid
    end

    it "終了日が開始日より前だと無効" do
      suspension = build(:client_suspension, start_date: Date.new(2026, 6, 20), end_date: Date.new(2026, 6, 19))
      expect(suspension).to be_invalid
      expect(suspension.errors[:end_date]).to be_present
    end

    it "終了日が空なら有効" do
      expect(build(:client_suspension, :open_ended)).to be_valid
    end
  end

  describe "Client#suspended_on?" do
    let(:client) { create(:client) }

    it "いずれかの休止期間に入っていればtrue" do
      create(:client_suspension, client: client, start_date: Date.new(2026, 6, 20), end_date: Date.new(2026, 6, 28))
      expect(client.suspended_on?(Date.new(2026, 6, 24))).to be true
      expect(client.suspended_on?(Date.new(2026, 6, 29))).to be false
    end
  end
end
