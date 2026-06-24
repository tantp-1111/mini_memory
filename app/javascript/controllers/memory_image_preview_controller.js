import { Controller } from "@hotwired/stimulus"

// Memory 投稿フォームで画像ファイルを選んだときに、blob URL でプレビューを差し替える。
// ERB が描画した既存画像 (edit 画面の display_image など) は残し、
// JS が追加したプレビュー img のみ disconnect 時に取り除く。
export default class extends Controller {
  static targets = ["container", "fileName"]

  connect() {
    this.currentObjectUrl = null
  }

  disconnect() {
    this.#revokeUrl()
    this.containerTarget
      .querySelectorAll("img[data-js-preview]")
      .forEach((el) => el.remove())
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
    img.dataset.jsPreview = "true"
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
