require "rails_helper"

RSpec.describe WeeklyScheduleBuilder do
  # 2026/6/15(月)〜6/21(日)の週で検証する
  let(:week_start) { Date.new(2026, 6, 15) }
  let(:tuesday) { Date.new(2026, 6, 16) }
  let(:wednesday) { Date.new(2026, 6, 17) }

  let(:pt) { create(:user, job: :pt) }
  let(:client) { create(:client) }

  def build(service_type: :rehab, only_user: nil)
    described_class.new(week_start: week_start, service_type: service_type, only_user: only_user)
  end

  def cells_on(date, service_type: :rehab, only_user: nil)
    build(service_type: service_type, only_user: only_user).rows.first&.dig(:cells, date) || []
  end

  describe "基本ルートの合成" do
    it "毎週ルートが該当曜日のセルに通常表示で入る" do
      visit = create(:recurring_visit, user: pt, client: client, wday: 2)
      cells = cells_on(tuesday)

      expect(cells.size).to eq 1
      expect(cells.first.recurring_visit).to eq visit
      expect(cells.first).to be_normal
      expect(cells_on(wednesday)).to be_empty
    end

    it "セル内は開始時刻順に並ぶ" do
      late = create(:recurring_visit, user: pt, client: client, wday: 2, start_time: "14:00", end_time: "14:40")
      early = create(:recurring_visit, user: pt, client: create(:client), wday: 2, start_time: "9:00", end_time: "9:40")

      expect(cells_on(tuesday).map(&:recurring_visit)).to eq [ early, late ]
    end

    it "区分違い・論理削除・終了した利用者は含まれない" do
      create(:recurring_visit, user: create(:user, job: :nurse), client: client) # nursing
      create(:recurring_visit, user: pt, client: client, wday: 2, discarded_at: Time.current)
      create(:recurring_visit, user: pt, client: create(:client, status: :ended), wday: 2)

      # rowsはアクティブなスタッフ全員の行を返すが、除外条件に該当するルートは
      # セルに現れないことを検証する(ptユーザー行は存在するが全セルが空)
      all_cells = build.rows.flat_map { |r| r[:cells].values }.flatten
      expect(all_cells).to be_empty
    end

    it "「自分のみ表示」では本人の行だけになる" do
      other = create(:user)
      create(:recurring_visit, user: pt, client: client, wday: 2)
      create(:recurring_visit, user: other, client: client, wday: 3)

      expect(build(only_user: pt).rows.map { |r| r[:user] }).to eq [ pt ]
    end
  end

  describe "変更の即時反映(色分け)" do
    let!(:route) { create(:recurring_visit, user: pt, client: client, wday: 2, start_time: "10:00", end_time: "10:40") }

    it "休みは対象日のコマを cancel 状態にする" do
      create(:schedule_change, recurring_visit: route, target_date: tuesday, change_type: :cancel)
      cell = cells_on(tuesday).first
      expect(cell).to be_canceled
      expect(cell.change).to be_present
    end

    it "振替は元コマを cancel、振替先(別日・別担当)に reschedule コマを足す" do
      other = create(:user, job: :pt)
      create(:schedule_change, :reschedule, recurring_visit: route, target_date: tuesday,
             new_date: wednesday, new_user: other, new_start_time: "13:00", new_end_time: "13:40")

      origin = cells_on(tuesday).first
      expect(origin).to be_canceled

      target = build.rows.find { |r| r[:user] == other }[:cells][wednesday].first
      expect(target).to be_rescheduled
      expect(target.start_time.strftime("%H:%M")).to eq "13:00"
    end

    it "管理者未確認の変更は unconfirmed、確認済みは外れる" do
      change = create(:schedule_change, recurring_visit: route, target_date: tuesday)
      expect(cells_on(tuesday).first).to be_unconfirmed

      change.confirm!(create(:user, role: :manager))
      expect(cells_on(tuesday).first).not_to be_unconfirmed
    end

    it "取り消した変更は反映されない(元の通常表示に戻る)" do
      change = create(:schedule_change, recurring_visit: route, target_date: tuesday)
      change.cancel_change!(pt)
      expect(cells_on(tuesday).first).to be_normal
    end
  end

  describe "休止期間の反映" do
    let!(:route) { create(:recurring_visit, user: pt, client: client, wday: 2) }

    it "休止期間内の日付はコマを非表示にし、期間後の日付では表示する" do
      # 6/15(月)〜6/21(日)の週。火曜=6/16。火曜を含む期間で休止
      create(:client_suspension, client: client, start_date: Date.new(2026, 6, 16), end_date: Date.new(2026, 6, 22))
      expect(cells_on(tuesday)).to be_empty

      # 翌週の火曜(6/23)は期間後なので表示される
      next_week = described_class.new(week_start: Date.new(2026, 6, 22), service_type: "rehab")
      expect(next_week.rows.first[:cells][Date.new(2026, 6, 23)]).not_to be_empty
    end

    it "終了日なしの休止は開始日以降ずっと非表示" do
      create(:client_suspension, :open_ended, client: client, start_date: Date.new(2026, 6, 16))
      expect(cells_on(tuesday)).to be_empty
    end
  end

  describe "#changes_this_week / #unconfirmed_count" do
    let!(:route) { create(:recurring_visit, user: pt, client: client, wday: 2) }

    it "今週の有効な変更を集め、未確認件数を数える" do
      create(:schedule_change, recurring_visit: route, target_date: tuesday)
      builder = build
      expect(builder.changes_this_week.size).to eq 1
      expect(builder.unconfirmed_count).to eq 1
    end
  end
end
