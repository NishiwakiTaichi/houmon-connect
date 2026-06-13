import { Controller } from "@hotwired/stimulus"

// Turbo Frame "modal" に中身が読み込まれたらBootstrapモーダルを開き、
// フォーム送信が成功(2xx/3xx)したら閉じる。422(バリデーション失敗)では開いたまま。
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
