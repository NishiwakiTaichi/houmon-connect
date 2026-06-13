require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  context "管理者のとき" do
    before { sign_in create(:user, role: :manager, job: :pt) }

    it "ふりがな付きでスタッフを登録できる" do
      expect {
        post admin_users_path, params: {
          user: {
            name: "山田 太郎", kana: "やまだ たろう", email: "yamada@example.com",
            job: "nurse", role: "staff", active: "1",
            password: "password", password_confirmation: "password"
          }
        }
      }.to change(User, :count).by(1)
      expect(User.last.kana).to eq "やまだ たろう"
    end

    it "ふりがなが空だと登録できない" do
      expect {
        post admin_users_path, params: {
          user: { name: "山田 太郎", kana: "", email: "y@example.com",
                  job: "nurse", role: "staff", password: "password", password_confirmation: "password" }
        }
      }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "パスワード空の編集では既存パスワードを保持する" do
      staff = create(:user, name: "旧名", kana: "きゅうめい")
      patch admin_user_path(staff), params: {
        user: { name: "新名", kana: "しんめい", email: staff.email, job: "pt", role: "staff",
                active: "1", password: "", password_confirmation: "" }
      }
      expect(staff.reload.name).to eq "新名"
      expect(staff.valid_password?("password")).to be true
    end
  end

  context "一般スタッフのとき" do
    before { sign_in create(:user, role: :staff) }

    it "スタッフ登録画面はトップへリダイレクトされる" do
      get new_admin_user_path
      expect(response).to redirect_to(root_path)
    end
  end
end
