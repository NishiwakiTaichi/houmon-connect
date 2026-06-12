FactoryBot.define do
  factory :client do
    sequence(:name) { |n| "テスト 利用者#{n}" }
    kana { "てすと りようしゃ" }
    status { :active }
    newcomer_policy { :ok }
    gender_restriction { :unrestricted }
  end
end
