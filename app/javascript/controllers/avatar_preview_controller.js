import { Controller } from "@hotwired/stimulus"

// アカウント編集フォームでアバター画像ファイルを選んだときに、blob URL で
// プレビューを差し替える。元 HTML を connect 時に退避しておき、Turbo back-cache
// 復帰時に添付済み画像 or イニシャル placeholder を復元する。
export default class extends Controller {
  static targets = ["container"]

  connect() {
    this.currentObjectUrl = null
    this.originalContainerHtml = this.containerTarget.innerHTML
  }

  disconnect() {
    this.#revokeUrl()
    if (this.originalContainerHtml != null) {
      this.containerTarget.innerHTML = this.originalContainerHtml
      this.originalContainerHtml = null
    }
  }

  render(event) {
    const file = event.target.files?.[0]
    if (!file) return

    this.#revokeUrl()
    this.currentObjectUrl = window.URL.createObjectURL(file)

    this.containerTarget.innerHTML = ""
    const avatarDiv = document.createElement("div")
    avatarDiv.className = "avatar"
    avatarDiv.dataset.jsPreview = "true"
    const innerDiv = document.createElement("div")
    innerDiv.className = "w-20 h-20 rounded-full overflow-hidden"
    const img = document.createElement("img")
    img.src = this.currentObjectUrl
    img.alt = "avatar preview"
    img.className = "w-full h-full object-cover"
    innerDiv.appendChild(img)
    avatarDiv.appendChild(innerDiv)
    this.containerTarget.appendChild(avatarDiv)
  }

  #revokeUrl() {
    if (this.currentObjectUrl) {
      window.URL.revokeObjectURL(this.currentObjectUrl)
      this.currentObjectUrl = null
    }
  }
}
