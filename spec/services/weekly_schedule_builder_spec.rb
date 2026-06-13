require "rails_helper"

RSpec.describe WeeklyScheduleBuilder do
  # 2026/6/15(月)〜6/21(日)の週で検証する
  let(:week_start) { Date.new(2026, 6, 15) }

  let(:pt) { create(:user, job: :pt) }
  let(:client) { create(:client) }

  def build_rows(service_type: :rehab, only_user: nil)
    described_class.new(week_start: week_start, service_type: service_type, only_user: only_user).rows
  end

  it "毎週ルートが該当曜日のセルに入る" do
    visit = create(:recurring_visit, user: pt, client: client, wday: 2) # 火曜
    rows = build_rows

    expect(rows.size).to eq 1
    expect(rows.first[:cells][Date.new(2026, 6, 16)]).to eq [ visit ]
    expect(rows.first[:cells][Date.new(2026, 6, 17)]).to be_empty
  end

  it "セル内は開始時刻順に並ぶ" do
    late = create(:recurring_visit, user: pt, client: client, wday: 2, start_time: "14:00", end_time: "14:40")
    early = create(:recurring_visit, user: pt, client: create(:client), wday: 2, start_time: "9:00", end_time: "9:40")

    cells = build_rows.first[:cells][Date.new(2026, 6, 16)]
    expect(cells).to eq [ early, late ]
  end

  it "サービス区分が違うルートは含まれない" do
    nurse = create(:user, job: :nurse)
    create(:recurring_visit, user: nurse, client: client) # 看護師なのでnursingになる
    expect(build_rows(service_type: :rehab)).to be_empty
  end

  it "論理削除済みルートと休止中利用者のルートは含まれない" do
    create(:recurring_visit, user: pt, client: client, wday: 2, discarded_at: Time.current)
    create(:recurring_visit, user: pt, client: create(:client, status: :suspended), wday: 2)

    expect(build_rows).to be_empty
  end

  it "「自分のみ表示」では本人の行だけになる" do
    other = create(:user)
    create(:recurring_visit, user: pt, client: client, wday: 2)
    create(:recurring_visit, user: other, client: client, wday: 3)

    rows = build_rows(only_user: pt)
    expect(rows.map { |r| r[:user] }).to eq [ pt ]
  end
end
