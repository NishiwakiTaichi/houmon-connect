class ChatworkNotifier
  extend RecurringVisitFormatter

  API_BASE   = "https://api.chatwork.com"
  ROUTE_ATTRS = %w[wday start_time end_time user_id].freeze

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
  # preloaded_changes: saved_changesのインメモリ値をジョブ経由で渡す場合に指定する。
  # 省略時はrv.saved_changesを参照する(直接呼び出し・テスト時の互換性を維持)
  def self.recurring_visit_updated(rv, operator, preloaded_changes: nil)
    post_message(build_recurring_visit_message(rv, verb: "変更", operator: operator, preloaded_changes: preloaded_changes))
  end

  def self.recurring_visit_discarded(rv, operator)
    post_message(build_recurring_visit_message(rv, verb: "削除", operator: operator))
  end

  # ── 内部実装 ─────────────────────────────────────────────────────────────

  private_class_method def self.post_message(body)
    conn = Faraday.new(url: API_BASE) do |f|
      f.request :url_encoded
      # TCP接続確立タイムアウト: Chatwork APIへの初期接続が遅延した場合に早期検知する
      f.options.open_timeout = 5
      # 応答待ちタイムアウト: リクエスト送信後にレスポンスが来ない場合の上限
      f.options.timeout = 10
    end
    conn.post("/v2/rooms/#{ENV['CHATWORK_ROOM_ID']}/messages") do |req|
      req.headers["x-chatworktoken"] = ENV["CHATWORK_API_TOKEN"]
      req.body = URI.encode_www_form(body: body)
    end
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
               "#{fmt_visit_time(change.new_start_time)}〜#{fmt_visit_time(change.new_end_time)} " \
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

  private_class_method def self.build_recurring_visit_message(rv, verb:, operator:, preloaded_changes: nil)
    service = I18n.t("enums.recurring_visit.service_type.#{rv.service_type}")

    route_line =
      if verb == "変更" && (changes = preloaded_changes || rv.saved_changes).present? && ROUTE_ATTRS.any? { |a| changes.key?(a) }
        before_wday  = changes.dig("wday", 0)       || rv.wday
        after_wday   = changes.dig("wday", 1)       || rv.wday
        before_start = changes.dig("start_time", 0) || rv.start_time
        after_start  = changes.dig("start_time", 1) || rv.start_time
        before_end   = changes.dig("end_time", 0)   || rv.end_time
        after_end    = changes.dig("end_time", 1)   || rv.end_time

        if changes.key?("user_id")
          before_user = User.find_by(id: changes["user_id"][0])&.name || "不明"
          after_user  = User.find_by(id: changes["user_id"][1])&.name || "不明"
        else
          before_user = rv.user.name
          after_user  = rv.user.name
        end

        "#{fmt_route(before_wday, before_start, before_end, before_user)} → " \
          "#{fmt_route(after_wday, after_start, after_end, after_user)}"
      else
        fmt_route(rv.wday, rv.start_time, rv.end_time, rv.user.name)
      end

    lines = [
      "[info][title]📋 基本ルート #{verb}[/title]",
      "利用者: #{rv.client.name} 様（#{service}）",
      "ルート: #{route_line}",
      "操作者: #{operator.name}",
      "[/info]"
    ]
    lines.join("\n")
  end

  private_class_method def self.fmt_date(date)
    "#{date.month}/#{date.day}(#{fmt_wday(date.wday)})"
  end
end
