# 登録/編集/取り消し/削除を ActivityLog に自動記録する。
# 記録漏れを防ぐため、コントローラではなくモデルのコールバックで記録する(設計書 2.2(3))。
# include する側は log_summary(action) を定義する。
module Loggable
  extend ActiveSupport::Concern

  included do
    after_create  -> { write_activity_log(:create) }
    after_update  -> { write_activity_log(detect_log_action) }
    after_destroy -> { write_activity_log(:destroy) }
  end

  private

  # 論理削除(canceled_at / discarded_at)が変わった更新は「取り消し/削除」として扱う
  def detect_log_action
    if saved_changes.key?("canceled_at") || saved_changes.key?("discarded_at")
      :cancel
    else
      :update
    end
  end

  def write_activity_log(action)
    # seed・コンソール・マイグレーション等(操作ユーザー不在)では記録しない
    return if Current.user.nil?

    ActivityLog.create!(
      user: Current.user,
      action: action,
      target: self,
      summary: log_summary(action),
      changeset: log_changeset(action)
    )
  end

  def log_changeset(action)
    if action == :destroy
      attributes.except("id", "created_at", "updated_at")
    else
      saved_changes.except("created_at", "updated_at")
    end
  end
end
