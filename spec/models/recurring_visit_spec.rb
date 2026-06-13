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

  describe "サービス区分の自動設定" do
    it "看護師が担当なら看護になる" do
      visit = build(:recurring_visit, user: build(:user, job: :nurse))
      visit.valid?
      expect(visit.service_type).to eq "nursing"
    end

    it "PT/OT/STが担当ならリハビリになる" do
      %i[pt ot st].each do |job|
        visit = build(:recurring_visit, user: build(:user, job: job))
        visit.valid?
        expect(visit.service_type).to eq "rehab"
      end
    end

    it "事務職を担当にすると無効" do
      visit = build(:recurring_visit, user: build(:user, job: :clerk))
      expect(visit).to be_invalid
      expect(visit.errors[:user]).to be_present
    end

    it "訪問スタッフ未選択時はサービス区分のエラーを出さない(自動設定項目のため)" do
      visit = build(:recurring_visit, user: nil)
      visit.valid?
      expect(visit.errors[:service_type]).to be_empty
      expect(visit.errors[:user]).to be_present
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

  describe "時間被りのチェック" do
    let(:staff) { create(:user, job: :pt) }
    let(:client) { create(:client) }
    # 火曜10:00-10:40に既存ルートを置く
    let!(:existing) do
      create(:recurring_visit, user: staff, client: client, wday: 2, start_time: "10:00", end_time: "10:40")
    end

    describe "(2-a) スタッフの時間被り = 完全禁止" do
      it "同じスタッフ・同じ曜日で時間が重なると無効になる" do
        dup = build(:recurring_visit, user: staff, client: create(:client), wday: 2, start_time: "10:20", end_time: "11:00")
        expect(dup).to be_invalid
        expect(dup.errors[:base].first).to include("すでに", "様の訪問が入っています")
      end

      it "時間が重ならなければ有効" do
        ok = build(:recurring_visit, user: staff, client: create(:client), wday: 2, start_time: "10:40", end_time: "11:20")
        expect(ok).to be_valid
      end

      it "曜日が違えば有効" do
        ok = build(:recurring_visit, user: staff, client: create(:client), wday: 3, start_time: "10:00", end_time: "10:40")
        expect(ok).to be_valid
      end

      it "頻度を考慮し、同じ週に当たらなければ有効(第1・3週 と 第2・4週)" do
        existing.update!(frequency: :nth_weeks, visit_weeks: "1,3")
        ok = build(:recurring_visit, user: staff, client: create(:client), wday: 2,
                   start_time: "10:00", end_time: "10:40", frequency: :nth_weeks, visit_weeks: "2,4")
        expect(ok).to be_valid
      end

      it "頻度を考慮し、同じ週に当たるなら無効(第1・3週 同士)" do
        existing.update!(frequency: :nth_weeks, visit_weeks: "1,3")
        ng = build(:recurring_visit, user: staff, client: create(:client), wday: 2,
                   start_time: "10:00", end_time: "10:40", frequency: :nth_weeks, visit_weeks: "1,3")
        expect(ng).to be_invalid
      end

      it "編集時に自分自身とは衝突しない" do
        expect(existing).to be_valid
      end
    end

    describe "(2-b) 利用者の時間被り = 警告どまり(禁止しない)" do
      it "別スタッフが同じ利用者・同じ時間でも有効(モデルは弾かない)" do
        other_staff = create(:user, job: :ot)
        same_client = build(:recurring_visit, user: other_staff, client: client, wday: 2,
                            start_time: "10:00", end_time: "10:40")
        expect(same_client).to be_valid
      end

      it "client_conflictsで重なりを検出できる(確認表示に使う)" do
        other_staff = create(:user, job: :ot)
        same_client = build(:recurring_visit, user: other_staff, client: client, wday: 2,
                            start_time: "10:00", end_time: "10:40")
        expect(same_client.client_conflicts).to include(existing)
      end
    end

    it "(2-a)は弾き、(2-b)は弾かないことを区別する" do
      other_staff = create(:user, job: :ot)
      staff_dup = build(:recurring_visit, user: staff, client: create(:client), wday: 2, start_time: "10:00", end_time: "10:40")
      client_dup = build(:recurring_visit, user: other_staff, client: client, wday: 2, start_time: "10:00", end_time: "10:40")

      expect(staff_dup).to be_invalid   # スタッフ重複は禁止
      expect(client_dup).to be_valid    # 利用者重複は警告どまり
    end
  end
end
