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
    # time型カラムはJSTをUTCに変換して保存するため、SQLに TimeWithZone を渡すと
    # タイムゾーン分ずれた値で比較される（例: 08:30 JST = 23:30 UTC → DB値も23:30だが
    # クエリ比較値は00:30 JST→などとなり早朝で23:30 < 00:30=FALSEになる）。
    # Ruby側でローカル時刻の「分」に変換して比較することで正確に判定する。
    new_start = local_minutes(start_time)
    new_end   = local_minutes(end_time)

    existing = StaffAbsence.hourly.where(user_id: user_id, date: date)
    existing = existing.where.not(id: id) if persisted?

    has_overlap = existing.any? do |ab|
      local_minutes(ab.start_time) < new_end && new_start < local_minutes(ab.end_time)
    end

    errors.add(:base, "時刻が重なる時間休が既に登録されています") if has_overlap
  end

  def local_minutes(t)
    t.in_time_zone.hour * 60 + t.in_time_zone.min
  end
end
