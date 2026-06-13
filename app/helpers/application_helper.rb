module ApplicationHelper
  # enumの値を日本語ラベルに変換する(config/locales/ja.yml の enums 以下を参照)
  def enum_t(record, attr)
    t("enums.#{record.model_name.i18n_key}.#{attr}.#{record.public_send(attr)}")
  end

  # ヘッダーの未確認件数バッジ(管理者のみ・見落とし防止)
  def unconfirmed_changes_badge
    return unless current_user&.manager?

    count = ScheduleChange.unconfirmed.count
    return if count.zero?

    tag.span(count, class: "nav-badge")
  end
end
