require "rails_helper"

RSpec.describe "StaffAbsences", type: :request do
  let(:manager) { create(:user, role: :manager) }
  let(:staff)   { create(:user, role: :staff) }
  let(:other)   { create(:user, role: :staff) }

  def absence_params(overrides = {})
    { staff_absence: { date: Date.current.to_s, absence_type: "full_day", note: "" }.merge(overrides) }
  end

  # ── 一覧 ──────────────────────────────────────────────────────────────────

  describe "GET /staff_absences" do
    let!(:own_absence)   { create(:staff_absence, user: staff,   date: Date.current) }
    let!(:other_absence) { create(:staff_absence, user: other,   date: Date.current) }

    it "一般スタッフも全スタッフの休暇を閲覧できる" do
      sign_in staff
      get staff_absences_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(staff.name).and include(other.name)
    end

    it "管理者も全スタッフの休暇を閲覧できる" do
      sign_in manager
      get staff_absences_path
      expect(response.body).to include(staff.name).and include(other.name)
    end
  end

  # ── 登録 ──────────────────────────────────────────────────────────────────

  describe "POST /staff_absences" do
    context "一般スタッフが自分の休暇を登録する" do
      before { sign_in staff }

      it "登録できる" do
        expect { post staff_absences_path, params: absence_params }
          .to change(StaffAbsence, :count).by(1)
        expect(StaffAbsence.last.user).to eq staff
      end

      it "user_idを他人に偽っても自分の休暇として登録される" do
        post staff_absences_path, params: absence_params(user_id: other.id)
        expect(StaffAbsence.last.user).to eq staff
      end
    end

    context "管理者が他スタッフの休暇を登録する" do
      before { sign_in manager }

      it "任意のスタッフで登録できる" do
        expect {
          post staff_absences_path, params: absence_params(user_id: staff.id)
        }.to change(StaffAbsence, :count).by(1)
        expect(StaffAbsence.last.user).to eq staff
      end
    end

    context "時間休で開始・終了時刻なし" do
      before { sign_in staff }

      it "登録を弾く" do
        expect {
          post staff_absences_path, params: absence_params(absence_type: "hourly")
        }.not_to change(StaffAbsence, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "時間休の複数スロット登録" do
      let(:hourly_params) do
        {
          staff_absence: {
            user_id: staff.id, date: Date.current.to_s,
            absence_type: "hourly", note: "",
            hourly_slots: [
              { start_time: "10:00", end_time: "11:00" },
              { start_time: "13:00", end_time: "14:00" }
            ]
          }
        }
      end

      before { sign_in staff }

      it "複数件まとめて登録できる" do
        expect { post staff_absences_path, params: hourly_params }
          .to change(StaffAbsence, :count).by(2)
      end

      it "バッチ内で時刻が重なる場合は全件弾く" do
        expect {
          post staff_absences_path, params: {
            staff_absence: {
              user_id: staff.id, date: Date.current.to_s,
              absence_type: "hourly", note: "",
              hourly_slots: [
                { start_time: "10:00", end_time: "11:30" },
                { start_time: "11:00", end_time: "12:00" }
              ]
            }
          }
        }.not_to change(StaffAbsence, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "DBに既存の時間休と重なるスロットは弾く" do
        create(:staff_absence, :hourly, user: staff, date: Date.current,
               start_time: "10:00", end_time: "11:00")
        expect {
          post staff_absences_path, params: {
            staff_absence: {
              user_id: staff.id, date: Date.current.to_s,
              absence_type: "hourly", note: "",
              hourly_slots: [ { start_time: "10:30", end_time: "11:30" } ]
            }
          }
        }.not_to change(StaffAbsence, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ── 削除 ──────────────────────────────────────────────────────────────────

  describe "DELETE /staff_absences/:id" do
    context "自分の休暇を削除" do
      let!(:absence) { create(:staff_absence, user: staff) }

      it "削除できる" do
        sign_in staff
        expect { delete staff_absence_path(absence) }
          .to change(StaffAbsence, :count).by(-1)
      end
    end

    context "他人の休暇を削除しようとする(一般スタッフ)" do
      let!(:absence) { create(:staff_absence, user: other) }

      it "削除できずリダイレクトされる" do
        sign_in staff
        expect { delete staff_absence_path(absence) }
          .not_to change(StaffAbsence, :count)
        expect(response).to redirect_to(staff_absences_path)
      end
    end

    context "管理者が他スタッフの休暇を削除" do
      let!(:absence) { create(:staff_absence, user: staff) }

      it "削除できる" do
        sign_in manager
        expect { delete staff_absence_path(absence) }
          .to change(StaffAbsence, :count).by(-1)
      end
    end
  end
end
