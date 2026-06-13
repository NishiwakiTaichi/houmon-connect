FactoryBot.define do
  factory :user do
    name { "テスト スタッフ" }
    kana { "てすと すたっふ" }
    sequence(:email) { |n| "staff#{n}@example.com" }
    password { "password" }
    role { :staff }
    job { :pt }
  end
end
