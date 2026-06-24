import { Controller } from "@hotwired/stimulus"

// ファイル選択時の画像プレビューを差し替える共通 controller。
// variant value で Memory 画像と Avatar 画像の構造差を吸収する。
//
// 使い方:
//   <div data-controller="image-preview"
//        data-image-preview-variant-value="memory">  // または "avatar"
//     <input type="file" data-action="change->image-preview#render">
//     <div data-image-preview-target="container"></div>
//     <p data-image-preview-target="fileName"></p>   // memory 用 (任意)
//   </div>
export default class extends Controller {
  static targets = ["container", "fileName"]
  static values = {
    variant: { type: String, default: "memory" }
  }

  connect() {
    this.currentObjectUrl = null
    // avatar は バリデーション失敗 / Turbo back-cache 復帰時に
    // 元の表示 (添付済み画像 or placeholder) を戻したいので原 HTML を退避する
    if (this.variantValue === "avatar") {
      this.originalContainerHtml = this.containerTarget.innerHTML
    }
  }

  disconnect() {
    this.#revokeUrl()
    // Turbo が body を差し替える前に preview をクリーンアップする。
    // ERB が描画した既存画像は残し、JS が追加した要素のみ消す。
    if (this.variantValue === "avatar") {
      if (this.originalContainerHtml != null) {
        this.containerTarget.innerHTML = this.originalContainerHtml
        this.originalContainerHtml = null
      }
    } else {
      this.containerTarget
        .querySelectorAll("img[data-js-preview]")
        .forEach((el) => el.remove())
      if (this.hasFileNameTarget) {
        this.fileNameTarget.textContent = ""
        this.fileNameTarget.classList.add("hidden")
      }
    }
  }

  render(event) {
    const file = event.target.files?.[0]
    if (!file) return

    this.#revokeUrl()
    this.currentObjectUrl = window.URL.createObjectURL(file)

    if (this.variantValue === "avatar") {
      this.#renderAvatar(this.currentObjectUrl)
    } else {
      this.#renderMemory(this.currentObjectUrl, file.name)
    }
  }

  #renderMemory(url, name) {
    this.containerTarget.innerHTML = ""
    const img = document.createElement("img")
    img.src = url
    img.alt = "image preview"
    img.dataset.jsPreview = "true"
    img.className = "h-full w-auto block mx-auto mt-2"
    this.containerTarget.appendChild(img)

    if (this.hasFileNameTarget) {
      this.fileNameTarget.textContent = name
      this.fileNameTarget.classList.remove("hidden")
    }
  }

  #renderAvatar(url) {
    this.containerTarget.innerHTML = ""
    const avatarDiv = document.createElement("div")
    avatarDiv.className = "avatar"
    avatarDiv.dataset.jsPreview = "true"
    const innerDiv = document.createElement("div")
    innerDiv.className = "w-20 h-20 rounded-full overflow-hidden"
    const img = document.createElement("img")
    img.src = url
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
