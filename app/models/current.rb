# リクエスト中の操作ユーザーを保持する(Loggableが記録者として参照する)。
# リクエストごとに自動リセットされる。
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
