Rails.application.routes.draw do
  devise_for :users

  # 週間スケジュール(schedules#index)完成までの仮トップ
  root "home#index"

  # 削除ルートは作らない(履歴を消さない方針。終了は status: ended で表現する)
  resources :clients, except: [ :destroy ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
