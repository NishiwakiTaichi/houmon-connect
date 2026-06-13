class ScheduleChange < ApplicationRecord
  belongs_to :recurring_visit
  belongs_to :registered_by, class_name: "User"
  belongs_to :new_user,     class_name: "User", optional: true
  belongs_to :confirmed_by, class_name: "User", optional: true
  belongs_to :canceled_by,  class_name: "User", optional: true

  enum :change_type, { cancel: 0, reschedule: 1, suspend: 2, resume: 3 }
  enum :reason,      { hospital_visit: 0, sick: 1, hospitalized: 2, personal: 3, other: 4 }
  enum :cm_contact,  { not_contacted: 0, contacted: 1 }, default: :not_contacted

  scope :effective,   -> { where(canceled_at: nil) }              # 取り消されていない有効な変更
  scope :unconfirmed, -> { effective.where(confirmed_at: nil) }   # 管理者が未確認の変更
  scope :recent_first, -> { order(created_at: :desc) }

  validates :target_date, presence: true
  validates :reason, presence: true
  validates :cm_contact, presence: true
  with_options if: :reschedule? do
    validates :new_date, :new_start_time, :new_end_time, presence: true
    validates :new_user, presence: true
  end

  # 休止/再開は登録した瞬間に利用者の状態へ反映する(設計書 2.2(5))
  after_create :apply_status_change

  def confirmed? = confirmed_at.present?
  def canceled?  = canceled_at.present?

  def confirm!(manager)
    update!(confirmed_at: Time.current, confirmed_by: manager)
  end

  def cancel_change!(user)
    # 休止/再開を取り消したら利用者の状態も戻す
    revert_status_change if suspend? || resume?
    update!(canceled_at: Time.current, canceled_by: user)
  end

  # その日付のコマ表示に影響する変更か(休み/振替は対象日当日に効く)
  def affects_cell_on?(date)
    (cancel? || reschedule?) && target_date == date
  end

  private

  def apply_status_change
    case change_type.to_sym
    when :suspend then recurring_visit.client.update!(status: :suspended)
    when :resume  then recurring_visit.client.update!(status: :active)
    end
  end

  def revert_status_change
    case change_type.to_sym
    when :suspend then recurring_visit.client.update!(status: :active)
    when :resume  then recurring_visit.client.update!(status: :suspended)
    end
  end
end
