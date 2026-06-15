Rails.application.routes.draw do
  devise_for :users

  # ログイン後のトップ = 週間スケジュール
  root "schedules#index"
  resources :schedules, only: [ :index ] # ?service=nursing/rehab &week=2026-06-15 &mine=1

  # 削除ルートは作らない(履歴を消さない方針。終了は status: ended で表現する)
  resources :clients, except: [ :destroy ] do
    # 休止期間の管理(追加・編集・削除)
    resources :suspensions, controller: "client_suspensions", only: %i[new create edit update destroy]
  end

  # destroyの代わりに論理削除(discard)のみを用意する
  resources :recurring_visits, except: [ :show, :destroy ] do
    member { patch :discard }
  end

  # 変更登録(即時反映)。confirm=管理者の確認チェック、cancel=論理削除。
  # 履歴を消さないため destroy は作らない。
  resources :schedule_changes, only: %i[index new create show edit update] do
    member do
      patch :confirm
      patch :cancel
    end
  end

  # 変更ログ(全スタッフ閲覧・改変不可なので index のみ)
  resources :activity_logs, only: [ :index ]

  # スタッフ休暇(一般は自分のみ登録/削除、管理者は全員分)
  resources :staff_absences, only: %i[index new create destroy]

  # スタッフ管理(管理者のみ)。MVPは職種・権限の確認用に一覧のみ
  namespace :admin do
    # 退職は active フラグで表すため destroy は作らない
    resources :users, except: [ :show, :destroy ]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
