class User < ApplicationRecord
  # 新規登録は管理者が行う運用のため registerable は外す(仕様書 F-1)
  # メール送信を伴う recoverable / confirmable はMVPでは使わない
  devise :database_authenticatable, :rememberable, :validatable

  has_many :recurring_visits, dependent: :restrict_with_error
  has_many :staff_absences, dependent: :destroy

  enum :role, { staff: 0, manager: 1 }, default: :staff
  enum :job,  { nurse: 0, pt: 1, ot: 2, st: 3, clerk: 4 }, default: :nurse

  validates :name, presence: true
  validates :kana, presence: true
end
