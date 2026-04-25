import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]
  static values = { successLabel: String }

  copy() {
    const text = this.sourceTarget.value
    const original = this.buttonTarget.textContent
    const restoreFailureState = () => {
      this.buttonTarget.textContent = original
      this.buttonTarget.classList.remove("btn-error")
    }
    const showFailure = (error) => {
      console.error("クリップボードへのコピーに失敗しました:", error)
      this.buttonTarget.textContent = "コピー失敗"
      this.buttonTarget.classList.add("btn-error")
      setTimeout(restoreFailureState, 2000)
    }

    if (!navigator.clipboard?.writeText) {
      showFailure(new Error("クリップボードへのコピーがサポートされていません"))
      return
    }

    navigator.clipboard.writeText(text).then(() => {
      this.buttonTarget.textContent = this.successLabelValue || "コピーしました"
      this.buttonTarget.disabled = true
      setTimeout(() => {
        this.buttonTarget.textContent = original
        this.buttonTarget.disabled = false
      }, 2000)
    }).catch(showFailure)
  }
}
