import { Controller } from "@hotwired/stimulus"

// プルダウンを検索付き(手入力で絞り込み)にする。
// Tom SelectはCDNの<script>で読み込まれるため window.TomSelect を参照する。
// searchFields に複数指定すると、その項目(例: text と data-kana)を横断して検索する。
export default class extends Controller {
  static values = { searchFields: { type: Array, default: ["text"] } }

  connect() {
    this.select = new window.TomSelect(this.element, {
      searchField: this.searchFieldsValue,
      maxOptions: null,
      allowEmptyOption: true,
      placeholder: this.element.querySelector("option[value='']")?.textContent
    })
  }

  disconnect() {
    if (this.select) {
      this.select.destroy()
      this.select = null
    }
  }
}
