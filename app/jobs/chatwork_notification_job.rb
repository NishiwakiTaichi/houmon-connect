class ChatworkNotificationJob < ApplicationJob
  queue_as :default

  # Chatwork API への接続・通信エラーは最大5回リトライ
  # wait: :polynomially_longer → 約 2s / 8s / 27s / 64s / 125s の増加
  # Render無料プランでスリープ中はリトライが止まるが、次回起動時にGoodJobがDB内の
  # 未処理ジョブを拾い直すためジョブ自体は消えない
  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 5

  # 通知対象レコードが見つからない場合(削除済み等)はリトライせず破棄
  discard_on ActiveRecord::RecordNotFound
  discard_on ActiveJob::DeserializationError

  # event:       通知種別(文字列)
  # record_id:   通知対象レコードのID
  # operator_id: 操作ユーザーのID(schedule_changeはレコードから取得するため省略可)
  # extra:       イベント固有の追加データ
  #              recurring_visit_updated では controller で captured した saved_changes のサブセット
  def perform(event, record_id, operator_id = nil, extra = {})
    operator = resolve_operator(event, record_id, operator_id)

    if operator&.demo?
      Rails.logger.info("[ChatworkNotificationJob] デモユーザー操作のため通知をスキップ: #{event} by #{operator.email}")
      return
    end

    case event
    when "schedule_change_created"
      ChatworkNotifier.schedule_change_created(ScheduleChange.find(record_id))

    when "schedule_change_canceled"
      ChatworkNotifier.schedule_change_canceled(ScheduleChange.find(record_id))

    when "suspension_created"
      ChatworkNotifier.suspension_created(ClientSuspension.find(record_id), operator)

    when "suspension_updated"
      ChatworkNotifier.suspension_updated(ClientSuspension.find(record_id), operator)

    when "suspension_destroyed"
      # コントローラ側でdestroy前にenqueueするため、ここでレコードが存在する
      ChatworkNotifier.suspension_destroyed(ClientSuspension.find(record_id), operator)

    when "recurring_visit_updated"
      rv = RecurringVisit.find(record_id)
      # saved_changesはsave直後のインメモリ状態のため、コントローラ側で
      # 事前にスナップショットを取りextraとして受け取る
      ChatworkNotifier.recurring_visit_updated(rv, operator, preloaded_changes: extra)

    when "recurring_visit_discarded"
      ChatworkNotifier.recurring_visit_discarded(RecurringVisit.find(record_id), operator)

    else
      Rails.logger.warn("[ChatworkNotificationJob] 未知のイベント: #{event}")
    end
  end

  private

  # イベント種別に応じてoperatorを解決する。
  # schedule_change系はレコードにoperator情報が埋め込まれているため引数不要。
  # その他はcontrollerがoperator_idを引数で渡す。
  # operatorがnilの場合はガードをスキップして通知を通す(誤抑止を防ぐ)。
  def resolve_operator(event, record_id, operator_id)
    case event
    when "schedule_change_created"
      ScheduleChange.find(record_id).registered_by
    when "schedule_change_canceled"
      ScheduleChange.find(record_id).canceled_by
    else
      User.find(operator_id) if operator_id
    end
  end
end
