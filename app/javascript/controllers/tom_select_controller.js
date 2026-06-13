import { Controller } from "@hotwired/stimulus"

// プルダウンを検索付き(手入力で絞り込み)にする。
// Tom SelectはCDNの<script>で読み込まれるため window.TomSelect を参照する。
// searchFields に複数指定すると、その項目(例: text と data-kana)を横断して検索する。
//
// 単一選択では、選択済みの名前が入力欄に文字として残り「遠藤 友一 さくらい」のように
// 連結されてしまう。これを防ぐため、フォーカス時に選択をいったん外して入力欄を空にし、
// 何も選び直さずに離れた場合は元の値を復元する。
export default class extends Controller {
  static values = { searchFields: { type: Array, default: ["text"] } }

  connect() {
    this.select = new window.TomSelect(this.element, {
      searchField: this.searchFieldsValue,
      maxOptions: null,
      allowEmptyOption: true,
      placeholder: this.element.querySelector("option[value='']")?.textContent,
      onFocus: () => this.clearForSearch(),
      onBlur: () => this.restoreIfEmpty()
    })
  }

  disconnect() {
    if (this.select) {
      this.select.destroy()
      this.select = null
    }
  }

  // フォーカス時: 現在の選択を覚えてから外し、入力欄を空にして検索しやすくする
  clearForSearch() {
    this.previousValue = this.select.getValue()
    if (this.previousValue) {
      this.select.clear(true) // silent(changeイベントを発火させない)
      this.select.setTextboxValue("")
    }
  }

  // 離れたとき何も選ばれていなければ、元の選択を黙って戻す
  restoreIfEmpty() {
    if (!this.select.getValue() && this.previousValue) {
      this.select.addItem(this.previousValue, true) // silent
    }
  }
}
