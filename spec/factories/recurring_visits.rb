FactoryBot.define do
  factory :recurring_visit do
    client
    user
    service_type { :rehab }
    wday { 2 } # 火曜
    start_time { "10:00" }
    end_time { "10:40" }
    frequency { :weekly }

    trait :nth_weeks do
      frequency { :nth_weeks }
      visit_weeks { "2,4" }
    end

    trait :biweekly do
      frequency { :biweekly }
      anchor_date { Date.new(2026, 6, 2) } # 火曜
    end
  end
end
