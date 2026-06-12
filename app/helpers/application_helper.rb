module ApplicationHelper
  # enumの値を日本語ラベルに変換する(config/locales/ja.yml の enums 以下を参照)
  def enum_t(record, attr)
    t("enums.#{record.model_name.i18n_key}.#{attr}.#{record.public_send(attr)}")
  end
end
