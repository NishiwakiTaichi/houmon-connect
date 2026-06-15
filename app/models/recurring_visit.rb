class RecurringVisit < ApplicationRecord
  include Loggable

  belongs_to :client
  belongs_to :user
  has_many :schedule_changes, dependent: :restrict_with_error

  WDAY_LABELS = %w[日 月 火 水 木 金 土].freeze
  # 頻度をまたいで「同じ週に重なるか」を判定するための走査週数(約1年)
  CONFLICT_SCAN_WEEKS = 53

  enum :service_type, { nursing: 0, rehab: 1 }
  enum :frequency, { weekly: 0, nth_weeks: 1, biweekly: 2 }, default: :weekly

  # サービス区分は担当スタッフの職種から自動設定する(看護師→看護、PT/OT/ST→リハビリ)
  before_validation :assign_service_type_from_user

  # サービス区分は訪問スタッフの職種から自動設定されるため、ユーザーが直接入力しない。
  # 訪問スタッフ未選択時は「訪問スタッフを選んでください」だけを出し、区分のエラーは出さない。
  validates :service_type, presence: true, if: -> { user.present? && !user.clerk? }
  validate :user_must_be_field_staff
  validates :wday, inclusion: { in: 0..6 }
  validates :start_time, :end_time, presence: true
  validate :end_time_after_start_time
  validates :visit_weeks, presence: true, if: :nth_weeks?
  validate :visit_weeks_format, if: :nth_weeks?
  validates :anchor_date, presence: true, if: :biweekly?
  validate :anchor_date_matches_wday, if: :biweekly?
  # (2-a) スタッフの時間被りは完全禁止。利用者の時間被り(2-b)はここでは弾かず、コントローラで確認する
  validate :staff_time_must_not_conflict

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

  def log_summary(action)
    verb = { "create" => "登録", "update" => "編集", "cancel" => "削除" }[action.to_s] || "変更"
    "#{client.name}の基本ルート(#{WDAY_LABELS[wday]} #{start_time.strftime("%-H:%M")} #{user.name})を#{verb}"
  end

  def log_client_id = client_id

  # (2-a) 同じ担当スタッフ・同じ曜日で実際に同じ週に重なる有効なルート
  def staff_conflicts
    find_conflicts(:user_id, user_id)
  end

  # (2-b) 同じ利用者・同じ曜日で実際に同じ週に重なる有効なルート(禁止はしない。確認に使う)
  def client_conflicts
    find_conflicts(:client_id, client_id)
  end

  private

  def find_conflicts(column, value)
    return [] if value.blank? || !checkable_for_conflict?

    RecurringVisit.kept.where(wday: wday, column => value).where.not(id: id)
      .select { |other| time_overlaps?(other) && shares_a_week_with?(other) }
  end

  # 時刻の重なり(time型は同じ基準日で保存されるため単純比較でよい)
  def time_overlaps?(other)
    start_time < other.end_time && other.start_time < end_time
  end

  # 頻度を考慮し、同じ曜日の訪問日が実際に同じ週に当たる週があるか
  # (例:「第1・3週」と「第2・4週」は重ならない)
  def shares_a_week_with?(other)
    return false unless wday == other.wday

    scan_dates.any? { |date| visit_on?(date) && other.visit_on?(date) }
  end

  def scan_dates
    offset = wday.zero? ? 6 : wday - 1 # 月曜始まりの週内オフセット
    first = Date.current.beginning_of_week + offset
    Array.new(CONFLICT_SCAN_WEEKS) { |i| first + (i * 7) }
  end

  # 頻度別の必須項目が揃っていないと visit_on? が判定できないため、揃うまで重複チェックは行わない
  def checkable_for_conflict?
    wday.present? && start_time.present? && end_time.present? &&
      !(nth_weeks? && visit_weeks.blank?) && !(biweekly? && anchor_date.blank?)
  end

  def staff_time_must_not_conflict
    conflict = staff_conflicts.first
    return unless conflict

    errors.add(:base,
      "#{user.name}さんの#{WDAY_LABELS[wday]}曜#{start_time.strftime("%-H:%M")}は" \
      "すでに#{conflict.client.name}様の訪問が入っています")
  end

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
