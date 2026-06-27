import { Controller } from "@hotwired/stimulus"

// Memory 投稿フォームで画像ファイルを選んだときに、blob URL でプレビューを差し替える。
// connect 時に container の元 HTML を退避しておき、disconnect で復元することで、
// edit 画面の ERB 描画済み既存画像が Turbo back-cache 復帰時に空になるのを防ぐ。
// avatar_preview_controller と同じパターン。
export default class extends Controller {
  static targets = ["container", "fileName"]

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
    if (this.hasFileNameTarget) {
      this.fileNameTarget.textContent = ""
      this.fileNameTarget.classList.add("hidden")
    }
  }

  render(event) {
    const file = event.target.files?.[0]
    if (!file) return

    this.#revokeUrl()
    this.currentObjectUrl = window.URL.createObjectURL(file)

    this.containerTarget.innerHTML = ""
    const img = document.createElement("img")
    img.src = this.currentObjectUrl
    img.alt = "image preview"
    img.className = "h-full w-auto block mx-auto mt-2"
    this.containerTarget.appendChild(img)

    if (this.hasFileNameTarget) {
      this.fileNameTarget.textContent = file.name
      this.fileNameTarget.classList.remove("hidden")
    }
  }

  #revokeUrl() {
    if (this.currentObjectUrl) {
      window.URL.revokeObjectURL(this.currentObjectUrl)
      this.currentObjectUrl = null
    }
  }
}
