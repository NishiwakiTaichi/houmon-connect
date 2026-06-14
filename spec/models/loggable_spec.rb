require "rails_helper"

# Loggable(全モデル共通の自動記録)の振る舞いを検証する
RSpec.describe Loggable do
  let(:operator) { create(:user) }

  before { Current.user = operator }

  describe "登録/編集" do
    it "利用者の登録で create ログが操作者付きで残る" do
      expect { create(:client) }.to change(ActivityLog, :count).by(1)
      log = ActivityLog.last
      expect(log.action).to eq "create"
      expect(log.user).to eq operator
      expect(log.target).to be_a(Client)
      expect(log.summary).to include("登録")
    end

    it "編集は update で、変更前→変更後の差分が changeset に残る" do
      client = create(:client)
      client.update!(name: "新しい名前")
      log = ActivityLog.last
      expect(log.action).to eq "update"
      expect(log.changeset["name"]).to eq [ client.name_previously_was, "新しい名前" ]
    end
  end

  describe "取り消し/削除" do
    it "基本ルートの discard は cancel(削除)として残る" do
      visit = create(:recurring_visit)
      expect { visit.discard! }.to change { ActivityLog.where(action: :cancel).count }.by(1)
      expect(ActivityLog.last.summary).to include("削除")
    end

    it "変更の取り消しは cancel として残る" do
      change = create(:schedule_change)
      change.cancel_change!(operator)
      expect(ActivityLog.last.action).to eq "cancel"
      expect(ActivityLog.last.summary).to include("取り消し")
    end

    it "変更の確認は update + summaryが「確認」になる" do
      change = create(:schedule_change)
      change.confirm!(create(:user, role: :manager))
      expect(ActivityLog.last.action).to eq "update"
      expect(ActivityLog.last.summary).to include("確認")
    end

    it "休止期間の物理削除は destroy として残る" do
      suspension = create(:client_suspension)
      expect { suspension.destroy }.to change { ActivityLog.where(action: :destroy).count }.by(1)
      expect(ActivityLog.last.summary).to include("削除")
    end
  end

  describe "操作ユーザー不在(seed等)" do
    it "Current.user が nil なら記録しない" do
      Current.user = nil
      expect { create(:client) }.not_to change(ActivityLog, :count)
    end
  end
end
