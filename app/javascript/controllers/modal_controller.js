import { Controller } from "@hotwired/stimulus"

// Turbo Streamからモーダルを確実に閉じるためのカスタムアクション。
// 削除は link + data-turbo-method による送信で、Turboが生成する一時フォームが
// モーダル要素の外にあるため turbo:submit-end がモーダルまでバブリングしないことがある。
// そのため保存/削除の成功レスポンス側から明示的に閉じる。
// Bootstrapの hide() を呼ぶと backdrop も body のクラスも正しく除去される。
if (window.Turbo && !window.Turbo.StreamActions.close_modal) {
  window.Turbo.StreamActions.close_modal = function () {
    const id = this.getAttribute("target") || "appModal"
    const el = document.getElementById(id)
    if (el && window.bootstrap) {
      window.bootstrap.Modal.getOrCreateInstance(el).hide()
    }
  }
}

// Turbo Frame "modal" に中身が読み込まれたらBootstrapモーダルを開く。
// 422(バリデーション失敗)はフレームだけ差し替わるので開いたまま。
// Bootstrap本体はCDNの<script>で読み込まれるため window.bootstrap を参照する。
export default class extends Controller {
  connect() {
    this.frame = this.element.querySelector("turbo-frame#modal")
    this.onFrameLoad = this.handleFrameLoad.bind(this)
    this.frame.addEventListener("turbo:frame-load", this.onFrameLoad)
    // 閉じたら中身を空にし、同じリンクを再度開けるよう src も外す
    this.element.addEventListener("hidden.bs.modal", () => {
      this.frame.innerHTML = ""
      this.frame.removeAttribute("src")
    })
  }

  disconnect() {
    this.frame.removeEventListener("turbo:frame-load", this.onFrameLoad)
  }

  get modal() {
    return window.bootstrap.Modal.getOrCreateInstance(this.element)
  }

  handleFrameLoad() {
    if (this.frame.innerHTML.trim() !== "") {
      this.modal.show()
    }
  }

  submitEnd(event) {
    if (event.detail.success) {
      this.modal.hide()
    }
  }
}
