module ClientsHelper
  # モックの凡例に合わせたバッジの短縮表記とCSSクラス
  NEWCOMER_BADGES = {
    "ok" => [ "同行○", "newok" ],
    "needs_contact" => [ "要連絡", "precall" ],
    "ng" => [ "同行×", "newng" ]
  }.freeze

  GENDER_BADGES = {
    "female_only" => [ "女性", "female" ],
    "male_only" => [ "男性", "male" ]
  }.freeze

  # 契約状態(利用中/終了)を表示。ただし現在休止期間中なら「休止中」を優先表示する
  def client_status_badge(client)
    if client.currently_suspended?
      tag.span("休止中", class: "status-badge st-suspended")
    else
      tag.span(enum_t(client, :status), class: "status-badge st-#{client.status}")
    end
  end

  def newcomer_badge(client)
    text, css = NEWCOMER_BADGES[client.newcomer_policy]
    tag.span(text, class: "attr-badge #{css}")
  end

  def gender_badge(client)
    text, css = GENDER_BADGES[client.gender_restriction]
    tag.span(text, class: "attr-badge #{css}") if text
  end

  # 週間スケジュールのコマ等で使う属性バッジまとめ(同行可・限定なしは表示しない)
  def client_attr_badges(client)
    badges = []
    badges << newcomer_badge(client) unless client.ok?
    badges << gender_badge(client)
    safe_join(badges.compact, " ")
  end
end
