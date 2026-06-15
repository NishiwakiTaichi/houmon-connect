FactoryBot.define do
  factory :staff_absence do
    user
    date          { Date.current.beginning_of_week + 1 } # 火曜
    absence_type  { :full_day }
    note          { nil }

    trait :am do
      absence_type { :am }
    end

    trait :pm do
      absence_type { :pm }
    end

    trait :hourly do
      absence_type { :hourly }
      start_time   { "09:00" }
      end_time     { "10:00" }
    end
  end
end
