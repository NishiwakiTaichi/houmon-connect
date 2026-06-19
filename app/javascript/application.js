// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// iOS SafariではBootstrapモーダル内からwindow.confirm()が呼ばれるとブロックされる。
// Turboのconfirm処理をBootstrapモーダルで代替してこの問題を回避する。
window.Turbo.config.confirmMethod = (message) => {
  return new Promise((resolve) => {
    const modal = document.getElementById("turboConfirmModal")
    if (!modal || !window.bootstrap) { resolve(window.confirm(message)); return }

    document.getElementById("turboConfirmMessage").textContent = message
    const bsModal = window.bootstrap.Modal.getOrCreateInstance(modal)
    let confirmed = false

    const okHandler = () => { confirmed = true }
    const hiddenHandler = () => {
      document.getElementById("turboConfirmOk").removeEventListener("click", okHandler)
      resolve(confirmed)
    }

    document.getElementById("turboConfirmOk").addEventListener("click", okHandler, { once: true })
    modal.addEventListener("hidden.bs.modal", hiddenHandler, { once: true })

    bsModal.show()
  })
}
