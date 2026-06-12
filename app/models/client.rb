class Client < ApplicationRecord
  # gender_restriction の「なし」は、ActiveRecordの Client.none と衝突するため
  # none ではなく unrestricted という値名にしている
  enum :status, { active: 0, suspended: 1, hospitalized: 2, ended: 3 }, default: :active
  enum :newcomer_policy, { ok: 0, needs_contact: 1, ng: 2 }, default: :ok
  enum :gender_restriction, { unrestricted: 0, female_only: 1, male_only: 2 }, default: :unrestricted

  validates :name, presence: true
  validates :kana, presence: true

  scope :ordered_by_kana, -> { order(:kana) }
end
