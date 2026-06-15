module ActivityLogsHelper
  TARGET_LABELS = {
    "Client" => "利用者",
    "RecurringVisit" => "基本ルート",
    "ScheduleChange" => "変更",
    "ClientSuspension" => "休止期間"
  }.freeze

  # 操作バッジ。論理削除(cancel)は対象で出し分ける:
  # 基本ルート/休止期間 → 赤「削除」、変更 → グレー「取り消し」
  def activity_action_badge(log)
    label, css =
      case log.action
      when "create"  then [ "登録", "act-create" ]
      when "update"  then confirm_log?(log) ? [ "確認", "act-confirm" ] : [ "編集", "act-update" ]
      when "destroy" then [ "削除", "act-destroy" ]
      when "cancel"
        log.target_type == "ScheduleChange" ? [ "取り消し", "act-cancel" ] : [ "削除", "act-destroy" ]
      else [ log.action, "act-update" ]
      end
    tag.span(label, class: "act-badge #{css}")
  end

  def activity_target_label(log)
    TARGET_LABELS.fetch(log.target_type, log.target_type)
  end

  # ログ本文。変更(ScheduleChange)は変更一覧パネル同等の詳細を出す。
  # それ以外は記録時の summary 内の利用者名をリンクに置き換えて返す。
  def activity_log_body(log)
    if log.target_type == "ScheduleChange" && log.target && !confirm_log?(log)
      schedule_change_log_detail(log.target)
    else
      log_body_with_client_link(log)
    end
  end

  # 管理者の確認チェック(confirmed_atだけが変わった変更の更新)か
  def confirm_log?(log)
    log.target_type == "ScheduleChange" && log.action == "update" && log.changeset.key?("confirmed_at")
  end

  def schedule_change_log_detail(change)
    visit = change.recurring_visit
    safe_join([
      tag.b(client_link(visit.client, suffix: " 様")),
      "（#{enum_t(visit, :service_type)}） ",
      change_after_label(change),
      " ｜ 理由: #{enum_t(change, :reason)}",
      (change.reason_detail.present? ? "（#{change.reason_detail}）" : ""),
      " ｜ ".html_safe,
      cm_contact_badge(change)
    ])
  end

  # 変更前→変更後の差分を日本語化した配列(更新ログ用)
  def activity_changes(log)
    klass = log_target_class(log)
    log.changeset.filter_map do |attr, values|
      next unless values.is_a?(Array) && values.size == 2
      next if attr.in?(%w[id created_at updated_at]) || attr.end_with?("_id")

      label = klass ? klass.human_attribute_name(attr) : attr
      "#{label}: #{humanize_log_value(klass, attr, values[0])} → #{humanize_log_value(klass, attr, values[1])}"
    end
  end

  private

  # summary 内の利用者名を clients#show へのリンクに置き換える。
  # log.client(denormalized)がなければ summary をそのまま返す。
  def log_body_with_client_link(log)
    client = log.client
    return log.summary if client.nil?

    name   = client.name
    summary = log.summary.to_s
    idx = summary.index(name)
    return log.summary if idx.nil?

    safe_join([
      summary[0, idx],
      client_link(client),
      summary[(idx + name.length)..]
    ])
  end

  def log_target_class(log)
    log.target_type.constantize
  rescue NameError
    nil
  end

  def humanize_log_value(klass, attr, value)
    return "（なし）" if value.nil? || value == ""

    if klass&.defined_enums&.key?(attr)
      I18n.t("enums.#{klass.model_name.i18n_key}.#{attr}.#{value}", default: value.to_s)
    elsif (formatted = format_log_datetime(value))
      formatted
    else
      value.to_s
    end
  end

  # ISO日時/日付文字列を「2026/6/15 3:52」「2026/6/20」に整形
  def format_log_datetime(value)
    return nil unless value.is_a?(String)

    if value.match?(/\A\d{4}-\d{2}-\d{2}T/)
      Time.zone.parse(value).strftime("%Y/%-m/%-d %-H:%M")
    elsif value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
      Date.parse(value).strftime("%Y/%-m/%-d")
    end
  rescue ArgumentError, Date::Error
    nil
  end
end
