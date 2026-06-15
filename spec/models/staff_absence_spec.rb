require "rails_helper"

RSpec.describe StaffAbsence, type: :model do
  let(:user) { create(:user) }
  let(:date) { Date.current }

  describe "時間休の重複チェック" do
    before do
      create(:staff_absence, :hourly, user: user, date: date,
             start_time: "10:00", end_time: "11:00")
    end

    it "時刻が重なる時間休は登録できない" do
      dup = build(:staff_absence, :hourly, user: user, date: date,
                  start_time: "10:30", end_time: "11:30")
      expect(dup).not_to be_valid
      expect(dup.errors[:base]).to include("時刻が重なる時間休が既に登録されています")
    end

    it "時刻が連続する(重ならない)時間休は登録できる" do
      next_ab = build(:staff_absence, :hourly, user: user, date: date,
                      start_time: "11:00", end_time: "12:00")
      expect(next_ab).to be_valid
    end

    it "時刻が完全に離れた時間休は登録できる" do
      later = build(:staff_absence, :hourly, user: user, date: date,
                    start_time: "14:00", end_time: "15:00")
      expect(later).to be_valid
    end

    it "別日の時間休は重複扱いにならない" do
      other_day = build(:staff_absence, :hourly, user: user, date: date + 1,
                        start_time: "10:00", end_time: "11:00")
      expect(other_day).to be_valid
    end

    it "別スタッフの同時刻は登録できる" do
      other_user = create(:user)
      other = build(:staff_absence, :hourly, user: other_user, date: date,
                    start_time: "10:00", end_time: "11:00")
      expect(other).to be_valid
    end
  end

  describe "終了時刻バリデーション" do
    it "終了が開始より前なら無効" do
      ab = build(:staff_absence, :hourly, user: user, date: date,
                 start_time: "11:00", end_time: "10:00")
      expect(ab).not_to be_valid
      expect(ab.errors[:end_time]).to be_present
    end
  end
end
