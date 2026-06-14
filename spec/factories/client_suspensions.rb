FactoryBot.define do
  factory :client_suspension do
    client
    start_date { Date.new(2026, 6, 20) }
    end_date { Date.new(2026, 6, 28) }
    note { "入院" }

    trait :open_ended do
      end_date { nil }
    end
  end
end
