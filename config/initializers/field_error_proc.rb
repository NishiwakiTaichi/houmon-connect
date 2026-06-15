# Bootstrap の btn-check パターンは `.btn-check + .btn`(隣接セレクター)に依存する。
# Rails デフォルトの <div class="field_with_errors"> ラッパーが input を囲むと
# label が隣接兄弟でなくなり、チェック状態が CSS に反映されなくなる。
# エラーはフォーム上部のアラートブロックで表示するため、ラッパーは不要。
ActionView::Base.field_error_proc = proc { |html_tag, _instance| html_tag }
