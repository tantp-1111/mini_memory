import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]
  static values = { successLabel: String }

  copy() {
    const text = this.sourceTarget.value
    navigator.clipboard.writeText(text).then(() => {
      const original = this.buttonTarget.textContent
      this.buttonTarget.textContent = "コピーしました"
      this.buttonTarget.disabled = true
      setTimeout(() => {
        this.buttonTarget.textContent = original
        this.buttonTarget.disabled = false
      }, 2000)
    })
  }
}
