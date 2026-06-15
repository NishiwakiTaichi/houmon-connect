class ChatworkNotifier
  API_BASE = "https://api.chatwork.com"
  WDAY_JA = %w[日 月 火 水 木 金 土].freeze

  # ── 公開API: 1メソッドを追加するだけで横展開できる ──────────────────────

  # スケジュール変更
  def self.schedule_change_created(change)
    post_message(build_change_message(change, verb: "登録", operator: change.registered_by))
  end

  def self.schedule_change_canceled(change)
    post_message(build_change_message(change, verb: "取り消し", operator: change.canceled_by))
  end

  # 休止期間
  def self.suspension_created(suspension, operator)
    post_message(build_suspension_message(suspension, verb: "登録", operator: operator))
  end

  def self.suspension_updated(suspension, operator)
    post_message(build_suspension_message(suspension, verb: "更新", operator: operator))
  end

  def self.suspension_destroyed(suspension, operator)
    post_message(build_suspension_message(suspension, verb: "削除", operator: operator))
  end

  # 基本ルート
  def self.recurring_visit_updated(rv, operator)
    post_message(build_recurring_visit_message(rv, verb: "変更", operator: operator))
  end

  def self.recurring_visit_discarded(rv, operator)
    post_message(build_recurring_visit_message(rv, verb: "削除", operator: operator))
  end

  # ── 内部実装 ─────────────────────────────────────────────────────────────

  private_class_method def self.post_message(body)
    conn = Faraday.new(url: API_BASE)
    conn.post("/v2/rooms/#{ENV['CHATWORK_ROOM_ID']}/messages") do |req|
      req.headers["x-chatworktoken"] = ENV["CHATWORK_API_TOKEN"]
      req.body = URI.encode_www_form(body: body)
    end
  rescue => e
    Rails.logger.error("[ChatworkNotifier] 通知失敗: #{e.class} #{e.message}")
  end

  private_class_method def self.build_change_message(change, verb:, operator:)
    rv      = change.recurring_visit
    client  = rv.client
    service = I18n.t("enums.recurring_visit.service_type.#{rv.service_type}")
    type    = I18n.t("enums.schedule_change.change_type.#{change.change_type}")
    reason  = I18n.t("enums.schedule_change.reason.#{change.reason}")
    cm      = I18n.t("enums.schedule_change.cm_contact.#{change.cm_contact}")
    cm_flag = change.not_contacted? ? " ⚠" : ""
    op_label = verb == "登録" ? "登録者" : "操作者"

    lines = [
      "[info][title]📝 スケジュール変更#{verb == '登録' ? '' : "（#{verb}）"}[/title]",
      "利用者: #{client.name} 様（#{service}）",
      "種別: #{type} / 対象日: #{fmt_date(change.target_date)}"
    ]

    if change.reschedule?
      new_u = change.new_user&.name || "未設定"
      lines << "振替先: #{fmt_date(change.new_date)} " \
               "#{fmt_time(change.new_start_time)}〜#{fmt_time(change.new_end_time)} " \
               "#{new_u}"
    end

    lines << "理由: #{reason}"
    lines << "ケアマネ: #{cm}#{cm_flag}"
    lines << "#{op_label}: #{operator.name}"
    lines << "[/info]"
    lines.join("\n")
  end

  private_class_method def self.build_suspension_message(suspension, verb:, operator:)
    client = suspension.client
    period = if suspension.end_date
      "#{fmt_date(suspension.start_date)}〜#{fmt_date(suspension.end_date)}"
    else
      "#{fmt_date(suspension.start_date)}〜（終了日未定）"
    end

    lines = [
      "[info][title]⏸ 休止期間 #{verb}[/title]",
      "利用者: #{client.name} 様",
      "期間: #{period}"
    ]
    lines << "備考: #{suspension.note}" if suspension.note.present?
    lines << "操作者: #{operator.name}"
    lines << "[/info]"
    lines.join("\n")
  end

  private_class_method def self.build_recurring_visit_message(rv, verb:, operator:)
    service = I18n.t("enums.recurring_visit.service_type.#{rv.service_type}")
    route   = "#{WDAY_JA[rv.wday]} #{fmt_time(rv.start_time)}〜#{fmt_time(rv.end_time)} 担当: #{rv.user.name}"

    lines = [
      "[info][title]📋 基本ルート #{verb}[/title]",
      "利用者: #{rv.client.name} 様（#{service}）",
      "ルート: #{route}",
      "操作者: #{operator.name}",
      "[/info]"
    ]
    lines.join("\n")
  end

  private_class_method def self.fmt_date(date)
    "#{date.month}/#{date.day}(#{WDAY_JA[date.wday]})"
  end

  private_class_method def self.fmt_time(time)
    time.strftime("%-H:%M")
  end
end
