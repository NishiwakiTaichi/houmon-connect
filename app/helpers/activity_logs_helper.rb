module ActivityLogsHelper
  # 操作 → [表示ラベル, CSSクラス]
  ACTION_STYLES = {
    "create"  => [ "登録", "act-create" ],
    "update"  => [ "編集", "act-update" ],
    "cancel"  => [ "取り消し", "act-cancel" ],
    "destroy" => [ "削除", "act-destroy" ]
  }.freeze

  TARGET_LABELS = {
    "Client" => "利用者",
    "RecurringVisit" => "基本ルート",
    "ScheduleChange" => "変更",
    "ClientSuspension" => "休止期間"
  }.freeze

  def activity_action_badge(log)
    label, css = ACTION_STYLES.fetch(log.action, [ log.action, "act-update" ])
    tag.span(label, class: "act-badge #{css}")
  end

  def activity_target_label(log)
    TARGET_LABELS.fetch(log.target_type, log.target_type)
  end

  # 変更前→変更後の差分を「属性: 旧 → 新」の人が読める配列にする
  def activity_changes(log)
    klass = log_target_class(log)
    log.changeset.filter_map do |attr, values|
      next unless values.is_a?(Array) && values.size == 2
      next if %w[id created_at updated_at].include?(attr)

      label = klass ? klass.human_attribute_name(attr) : attr
      "#{label}: #{activity_value(values[0])} → #{activity_value(values[1])}"
    end
  end

  private

  def log_target_class(log)
    log.target_type.constantize
  rescue NameError
    nil
  end

  def activity_value(value)
    value.nil? || value == "" ? "（なし）" : value.to_s
  end
end
