class StaffAbsence < ApplicationRecord
  include Loggable

  belongs_to :user

  enum :absence_type, { full_day: 0, am: 1, pm: 2, hourly: 3 }

  validates :date, presence: true
  validates :absence_type, presence: true
  validates :start_time, :end_time, presence: true, if: :hourly?
  validate :end_time_after_start_time, if: -> { hourly? && start_time.present? && end_time.present? }
  validate :no_overlapping_hourly,     if: -> { hourly? && start_time.present? && end_time.present? && date.present? && user.present? }

  def log_summary(action)
    type_label = I18n.t("enums.staff_absence.absence_type.#{absence_type}")
    verb = action.to_s == "destroy" ? "削除" : "登録"
    "#{user.name}の休暇（#{date.strftime("%-m/%-d")} #{type_label}）を#{verb}"
  end

  def log_client_id = nil

  private

  def end_time_after_start_time
    errors.add(:end_time, "は開始時刻より後にしてください") if end_time <= start_time
  end

  def no_overlapping_hourly
    overlap = StaffAbsence.hourly
      .where(user: user, date: date)
      .where.not(id: id)
      .where("start_time < ? AND end_time > ?", end_time, start_time)
    errors.add(:base, "時刻が重なる時間休が既に登録されています") if overlap.exists?
  end
end
