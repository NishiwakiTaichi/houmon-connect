FactoryBot.define do
  factory :schedule_change do
    recurring_visit
    registered_by factory: %i[user]
    change_type { :cancel }
    target_date { Date.new(2026, 6, 16) } # 火曜
    reason { :sick }
    cm_contact { :contacted }

    trait :reschedule do
      change_type { :reschedule }
      new_date { Date.new(2026, 6, 17) } # 水曜
      new_start_time { "11:00" }
      new_end_time { "11:40" }
      new_user factory: %i[user]
    end
  end
end
