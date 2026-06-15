class ChatworkNotifier
  API_BASE = "https://api.chatwork.com"
  WDAY_JA = %w[日 月 火 水 木 金 土].freeze

  # ── 公開API: 操作ごとにメソッドを1つ追加するだけで横展開できる ──────────

  def self.schedule_change_created(change)
    post_message(build_message(change, verb: "登録"))
  end

  # 今後追加予定:
  # def self.schedule_change_canceled(change)
  #   post_message(build_message(change, verb: "取り消し"))
  # end

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

  private_class_method def self.build_message(change, verb:)
    rv      = change.recurring_visit
    client  = rv.client
    service = I18n.t("enums.recurring_visit.service_type.#{rv.service_type}")
    type    = I18n.t("enums.schedule_change.change_type.#{change.change_type}")
    reason  = I18n.t("enums.schedule_change.reason.#{change.reason}")
    cm      = I18n.t("enums.schedule_change.cm_contact.#{change.cm_contact}")
    cm_flag = change.not_contacted? ? " ⚠" : ""

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
    lines << "登録者: #{change.registered_by.name}"
    lines << "[/info]"

    lines.join("\n")
  end

  private_class_method def self.fmt_date(date)
    "#{date.month}/#{date.day}(#{WDAY_JA[date.wday]})"
  end

  private_class_method def self.fmt_time(time)
    time.strftime("%-H:%M")
  end
end
