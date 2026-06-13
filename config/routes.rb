Rails.application.routes.draw do
  devise_for :users

  # ログイン後のトップ = 週間スケジュール
  root "schedules#index"
  resources :schedules, only: [ :index ] # ?service=nursing/rehab &week=2026-06-15 &mine=1

  # 削除ルートは作らない(履歴を消さない方針。終了は status: ended で表現する)
  resources :clients, except: [ :destroy ]

  # destroyの代わりに論理削除(discard)のみを用意する
  resources :recurring_visits, except: [ :show, :destroy ] do
    member { patch :discard }
  end

  # スタッフ管理(管理者のみ)。MVPは職種・権限の確認用に一覧のみ
  namespace :admin do
    resources :users, only: [ :index ]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
