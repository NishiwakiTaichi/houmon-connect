class ActivityLog < ApplicationRecord
  belongs_to :user
  # 対象は物理削除され得る(休止期間など)ため optional。表示は保存済みの summary を使う
  belongs_to :target, polymorphic: true, optional: true

  # create/destroy 等はActiveRecordのメソッドと衝突するため prefix を付ける
  enum :action, { create: 0, update: 1, cancel: 2, destroy: 3 }, prefix: true

  scope :recent_first, -> { order(created_at: :desc) }
end
