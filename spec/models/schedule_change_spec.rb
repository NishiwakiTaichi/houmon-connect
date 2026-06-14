require "rails_helper"

RSpec.describe ScheduleChange, type: :model do
  let(:client) { create(:client, status: :active) }
  let(:route) { create(:recurring_visit, client: client) }

  describe "scope" do
    it "effective は取り消されていない変更だけ" do
      live = create(:schedule_change, recurring_visit: route)
      gone = create(:schedule_change, recurring_visit: route)
      gone.cancel_change!(create(:user))
      expect(ScheduleChange.effective).to contain_exactly(live)
    end

    it "unconfirmed は有効かつ未確認だけ" do
      unconfirmed = create(:schedule_change, recurring_visit: route)
      confirmed = create(:schedule_change, recurring_visit: route)
      confirmed.confirm!(create(:user, role: :manager))
      expect(ScheduleChange.unconfirmed).to contain_exactly(unconfirmed)
    end
  end

  describe "#confirm!" do
    it "confirmed_at と confirmed_by を記録する" do
      change = create(:schedule_change, recurring_visit: route)
      manager = create(:user, role: :manager)
      change.confirm!(manager)
      expect(change).to be_confirmed
      expect(change.confirmed_by).to eq manager
    end
  end

  describe "#cancel_change!(論理削除)" do
    it "canceled_at を記録し、レコードは消えない" do
      change = create(:schedule_change, recurring_visit: route)
      expect { change.cancel_change!(create(:user)) }.not_to change(ScheduleChange, :count)
      expect(change).to be_canceled
    end
  end

  describe "種別" do
    it "休み/振替の2種類のみ(休止/再開は廃止)" do
      expect(ScheduleChange.change_types.keys).to contain_exactly("cancel", "reschedule")
    end
  end

  describe "バリデーション" do
    it "振替なのに振替先が無いと無効" do
      change = build(:schedule_change, change_type: :reschedule, new_date: nil, new_user: nil)
      expect(change).to be_invalid
      expect(change.errors[:new_date]).to be_present
    end

    it "対象日が無いと無効" do
      expect(build(:schedule_change, target_date: nil)).to be_invalid
    end

    it "種別が未選択だと無効で、日本語メッセージを返す" do
      change = build(:schedule_change, change_type: nil)
      expect(change).to be_invalid
      expect(change.errors.full_messages).to include("種別を選択してください")
    end
  end
end
