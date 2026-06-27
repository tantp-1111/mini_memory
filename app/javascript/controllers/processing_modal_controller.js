import { Controller } from "@hotwired/stimulus"

// フォーム送信中(同期の画像処理の数秒間)だけモーダルのスピナーを表示する。
// turbo:submit-start で開き、turbo:submit-end(レスポンス受信)で閉じる。
export default class extends Controller {
  static targets = ["modal"]

  show() {
    // 新しい画像が選択されている時だけ表示（編集で画像未変更ならリクエストは速いので出さない）
    const fileInput = this.element.querySelector('input[type="file"]')
    if (fileInput && fileInput.files.length === 0) return

    this.modalTarget.classList.remove("hidden")
  }

  hide() {
    this.modalTarget.classList.add("hidden")
  }
}
