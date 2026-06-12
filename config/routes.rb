Rails.application.routes.draw do
  devise_for :users

  # 週間スケジュール(schedules#index)完成までの仮トップ
  root "home#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
