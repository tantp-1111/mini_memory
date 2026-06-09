import { Controller } from "@hotwired/stimulus"

// スクロールで要素が画面内に入ったタイミングでフェード+スライドさせる
// 使い方:
//   <div data-controller="scroll-reveal"
//        data-scroll-reveal-delay-value="200"
//        class="opacity-0 translate-y-8 transition-all duration-700 ease-out">
export default class extends Controller {
  static values = { delay: { type: Number, default: 0 } }

  connect() {
    // OS 設定でアニメーション抑制を選んでいる場合は即座に表示
    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (reduceMotion) {
      this.reveal()
      return
    }

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return
          setTimeout(() => this.reveal(), this.delayValue)
          this.observer.unobserve(entry.target)
        })
      },
      { threshold: 0.15 }
    )
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  reveal() {
    this.element.classList.remove("opacity-0", "translate-y-8")
    this.element.classList.add("opacity-100", "translate-y-0")
  }
}
