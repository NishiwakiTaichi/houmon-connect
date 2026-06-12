require "rails_helper"

# visit_on? は週間スケジュール合成の心臓部のため、3種頻度×境界条件を網羅する
# (基準: 2026年6月の火曜日は 2, 9, 16, 23, 30 日)
RSpec.describe RecurringVisit, type: :model do
  describe "#visit_on?" do
    context "曜日が一致しないとき" do
      it "頻度によらずfalseを返す" do
        visit = build(:recurring_visit, wday: 2)
        expect(visit.visit_on?(Date.new(2026, 6, 17))).to be false # 水曜
      end
    end

    context "毎週(weekly)のとき" do
      let(:visit) { build(:recurring_visit, wday: 2, frequency: :weekly) }

      it "同じ曜日なら毎週trueを返す" do
        expect(visit.visit_on?(Date.new(2026, 6, 2))).to be true
        expect(visit.visit_on?(Date.new(2026, 6, 9))).to be true
        expect(visit.visit_on?(Date.new(2026, 6, 16))).to be true
      end
    end

    context "第n週(nth_weeks)のとき" do
      let(:visit) { build(:recurring_visit, :nth_weeks, wday: 2, visit_weeks: "2,4") }

      it "指定した週ならtrueを返す" do
        expect(visit.visit_on?(Date.new(2026, 6, 9))).to be true   # 第2週
        expect(visit.visit_on?(Date.new(2026, 6, 23))).to be true  # 第4週
      end

      it "指定していない週はfalseを返す" do
        expect(visit.visit_on?(Date.new(2026, 6, 2))).to be false  # 第1週
        expect(visit.visit_on?(Date.new(2026, 6, 16))).to be false # 第3週
        expect(visit.visit_on?(Date.new(2026, 6, 30))).to be false # 第5週
      end

      it "月をまたいでも第n週で判定できる" do
        expect(visit.visit_on?(Date.new(2026, 7, 14))).to be true  # 7月の第2週
        expect(visit.visit_on?(Date.new(2026, 7, 7))).to be false  # 7月の第1週
      end
    end

    context "2週ごと(biweekly)のとき" do
      let(:visit) { build(:recurring_visit, :biweekly, wday: 2, anchor_date: Date.new(2026, 6, 2)) }

      it "基準日当日と偶数週後はtrueを返す" do
        expect(visit.visit_on?(Date.new(2026, 6, 2))).to be true   # 基準日(0週後)
        expect(visit.visit_on?(Date.new(2026, 6, 16))).to be true  # 2週後
        expect(visit.visit_on?(Date.new(2026, 6, 30))).to be true  # 4週後
      end

      it "奇数週後はfalseを返す" do
        expect(visit.visit_on?(Date.new(2026, 6, 9))).to be false  # 1週後
        expect(visit.visit_on?(Date.new(2026, 6, 23))).to be false # 3週後
      end

      it "月をまたいでも2週間隔を保つ" do
        expect(visit.visit_on?(Date.new(2026, 7, 14))).to be true  # 6週後
        expect(visit.visit_on?(Date.new(2026, 7, 7))).to be false  # 5週後
      end
    end
  end

  describe "バリデーション" do
    it "終了時刻が開始時刻以前だと無効" do
      visit = build(:recurring_visit, start_time: "10:00", end_time: "10:00")
      expect(visit).to be_invalid
      expect(visit.errors[:end_time]).to be_present
    end

    it "第n週なのに週指定が空だと無効" do
      visit = build(:recurring_visit, frequency: :nth_weeks, visit_weeks: "")
      expect(visit).to be_invalid
    end

    it "週指定に1〜5以外が含まれると無効" do
      visit = build(:recurring_visit, frequency: :nth_weeks, visit_weeks: "0,6")
      expect(visit).to be_invalid
    end

    it "2週ごとなのに基準日が空だと無効" do
      visit = build(:recurring_visit, frequency: :biweekly, anchor_date: nil)
      expect(visit).to be_invalid
    end

    it "基準日の曜日がルートの曜日と違うと無効" do
      visit = build(:recurring_visit, frequency: :biweekly, wday: 2, anchor_date: Date.new(2026, 6, 3)) # 水曜
      expect(visit).to be_invalid
      expect(visit.errors[:anchor_date]).to be_present
    end

    it "正しい値なら有効(3種頻度とも)" do
      expect(build(:recurring_visit)).to be_valid
      expect(build(:recurring_visit, :nth_weeks)).to be_valid
      expect(build(:recurring_visit, :biweekly)).to be_valid
    end
  end

  describe "#discard!(論理削除)" do
    it "discarded_atが記録され、keptスコープから外れる" do
      visit = create(:recurring_visit)
      expect { visit.discard! }.to change { RecurringVisit.kept.count }.by(-1)
      expect(visit.reload).to be_discarded
    end
  end
end
