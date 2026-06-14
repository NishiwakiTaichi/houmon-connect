class Client < ApplicationRecord
  has_many :recurring_visits, dependent: :restrict_with_error
  has_many :client_suspensions, dependent: :destroy

  # status は契約状態のみ(利用中/終了)。「休止中」は休止期間(client_suspensions)から導出する。
  # gender_restriction の「なし」は ActiveRecord の Client.none と衝突するため unrestricted にしている。
  enum :status, { active: 0, ended: 1 }, default: :active
  enum :newcomer_policy, { ok: 0, needs_contact: 1, ng: 2 }, default: :ok
  enum :gender_restriction, { unrestricted: 0, female_only: 1, male_only: 2 }, default: :unrestricted

  validates :name, presence: true
  validates :kana, presence: true

  scope :ordered_by_kana, -> { order(:kana) }

  # その日が、いずれかの休止期間に入っているか
  def suspended_on?(date)
    client_suspensions.any? { |s| s.covers?(date) }
  end

  # 今日時点で休止中か(バッジ表示などの導出に使う)
  def currently_suspended?
    suspended_on?(Date.current)
  end

  # 氏名・ふりがなの部分一致(大文字小文字を無視)
  scope :search_by_name, ->(query) {
    pattern = "%#{sanitize_sql_like(query)}%"
    where("name ILIKE :q OR kana ILIKE :q", q: pattern)
  }
end
