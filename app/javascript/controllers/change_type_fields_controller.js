import { Controller } from "@hotwired/stimulus"

// 変更登録フォームで、種別=振替のときだけ「振替先」の入力欄を表示する
export default class extends Controller {
  static targets = ["reschedule"]

  connect() {
    this.toggle()
  }

  toggle() {
    const checked = this.element.querySelector('input[name="schedule_change[change_type]"]:checked')
    const type = checked ? checked.value : "cancel"
    this.rescheduleTarget.hidden = type !== "reschedule"
  }
}
