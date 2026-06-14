class ClientSuspension < ApplicationRecord
  belongs_to :client

  validates :start_date, presence: true
  validate :end_date_after_start_date

  scope :by_start_date, -> { order(:start_date) }

  # date がこの休止期間に入っているか(終了日なし=開始日以降ずっと休止)
  def covers?(date)
    start_date <= date && (end_date.nil? || date <= end_date)
  end

  def ongoing? = end_date.nil?

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "は開始日以降にしてください") if end_date < start_date
  end
end
