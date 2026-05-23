import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["badge", "container"]

  toggle(event) {
    const badge = event.currentTarget
    const childId = badge.dataset.childId
    const isSelected = badge.dataset.selected === "true"

    isSelected ? this.#deselect(badge, childId) : this.#select(badge, childId)
  }

  selectAll() {
    this.badgeTargets.forEach((badge) => {
      const childId = badge.dataset.childId
      if (badge.dataset.selected !== "true") this.#select(badge, childId)
    })
  }

  #select(badge, childId) {
    badge.classList.add("badge-primary")
    badge.classList.remove("badge-outline")
    badge.dataset.selected = "true"

    const existing = this.containerTarget.querySelector(`input[data-child-id="${childId}"]`)
    if (!existing) {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "memory[child_ids][]"
      input.value = childId
      input.dataset.childId = childId
      this.containerTarget.appendChild(input)
    }
  }

  #deselect(badge, childId) {
    badge.classList.remove("badge-primary")
    badge.classList.add("badge-outline")
    badge.dataset.selected = "false"

    // 該当するinput要素を削除
    const input = this.containerTarget.querySelector(`input[data-child-id="${childId}"]`)
    if (input) input.remove()
  }
}