class ScheduleChange < ApplicationRecord
  belongs_to :recurring_visit
  belongs_to :registered_by, class_name: "User"
  belongs_to :new_user,     class_name: "User", optional: true
  belongs_to :confirmed_by, class_name: "User", optional: true
  belongs_to :canceled_by,  class_name: "User", optional: true

  # 休止/再開は休止期間(ClientSuspension)で管理するため、種別は休み/振替の2つだけ
  enum :change_type, { cancel: 0, reschedule: 1 }
  enum :reason,      { hospital_visit: 0, sick: 1, hospitalized: 2, personal: 3, other: 4 }
  enum :cm_contact,  { not_contacted: 0, contacted: 1 }, default: :not_contacted

  scope :effective,   -> { where(canceled_at: nil) }              # 取り消されていない有効な変更
  scope :unconfirmed, -> { effective.where(confirmed_at: nil) }   # 管理者が未確認の変更
  scope :recent_first, -> { order(created_at: :desc) }

  # 種別は必須。未選択のままだとDBのNOT NULL制約で500になるため、モデルで弾く
  validates :change_type, presence: { message: "を選択してください" }
  validates :target_date, presence: true
  validates :reason, presence: true
  validates :cm_contact, presence: true
  with_options if: :reschedule? do
    validates :new_date, :new_start_time, :new_end_time, presence: true
    validates :new_user, presence: true
  end

  def confirmed? = confirmed_at.present?
  def canceled?  = canceled_at.present?

  def confirm!(manager)
    update!(confirmed_at: Time.current, confirmed_by: manager)
  end

  def cancel_change!(user)
    update!(canceled_at: Time.current, canceled_by: user)
  end

  # その日付のコマ表示に影響する変更か(休み/振替は対象日当日に効く)
  def affects_cell_on?(date)
    target_date == date
  end
end
