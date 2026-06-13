import { Controller } from "@hotwired/stimulus"

// 基本ルートフォームで、選択した頻度に応じて入力欄を出し分ける
export default class extends Controller {
  static targets = ["nthWeeks", "biweekly"]

  connect() {
    this.toggle()
  }

  toggle() {
    const checked = this.element.querySelector('input[name="recurring_visit[frequency]"]:checked')
    const frequency = checked ? checked.value : "weekly"
    this.nthWeeksTarget.hidden = frequency !== "nth_weeks"
    this.biweeklyTarget.hidden = frequency !== "biweekly"
  }
}
