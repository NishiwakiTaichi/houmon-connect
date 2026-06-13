class RecurringVisit < ApplicationRecord
  belongs_to :client
  belongs_to :user

  enum :service_type, { nursing: 0, rehab: 1 }
  enum :frequency, { weekly: 0, nth_weeks: 1, biweekly: 2 }, default: :weekly

  # サービス区分は担当スタッフの職種から自動設定する(看護師→看護、PT/OT/ST→リハビリ)
  before_validation :assign_service_type_from_user

  validates :service_type, presence: true
  validate :user_must_be_field_staff
  validates :wday, inclusion: { in: 0..6 }
  validates :start_time, :end_time, presence: true
  validate :end_time_after_start_time
  validates :visit_weeks, presence: true, if: :nth_weeks?
  validate :visit_weeks_format, if: :nth_weeks?
  validates :anchor_date, presence: true, if: :biweekly?
  validate :anchor_date_matches_wday, if: :biweekly?

  # 論理削除: 削除済みを除いた有効なルートだけを返す(設計書 2.2)
  scope :kept, -> { where(discarded_at: nil) }
  scope :in_week_order, -> { order(:wday, :start_time) }

  def discarded? = discarded_at.present?

  def discard!
    update!(discarded_at: Time.current)
  end

  # date がこのルートの訪問対象日かどうか(週間スケジュール合成の核になるメソッド)
  def visit_on?(date)
    return false unless date.wday == wday

    case frequency.to_sym
    when :weekly
      true
    when :nth_weeks
      visit_week_numbers.include?(nth_week_of(date))
    when :biweekly
      ((date - anchor_date).to_i / 7).even?
    end
  end

  # "2,4" → [2, 4]
  def visit_week_numbers
    visit_weeks.to_s.split(",").map(&:to_i)
  end

  private

  def assign_service_type_from_user
    return if user.blank? || user.clerk?

    self.service_type = user.nurse? ? :nursing : :rehab
  end

  def user_must_be_field_staff
    errors.add(:user, "に事務職のスタッフは選べません") if user&.clerk?
  end

  # その日が第何週か(1〜5)
  def nth_week_of(date)
    ((date.day - 1) / 7) + 1
  end

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    errors.add(:end_time, "は開始時刻より後にしてください") if end_time <= start_time
  end

  def visit_weeks_format
    return if visit_weeks.blank?

    errors.add(:visit_weeks, "は第1〜5週から選んでください") unless visit_week_numbers.any? && visit_week_numbers.all? { |n| (1..5).cover?(n) }
  end

  def anchor_date_matches_wday
    return if anchor_date.blank? || wday.blank?

    errors.add(:anchor_date, "は曜日と同じ曜日の日付にしてください") unless anchor_date.wday == wday
  end
end
