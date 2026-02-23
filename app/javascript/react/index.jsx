import React from "react"
import { createRoot } from "react-dom/client"
import App from "./App"
import MemoryGame from "./MemoryGame"

// Appのマウントとアンマウント
function mountReactApp() {
  const element = document.getElementById("react-root")
  if (!element) return

  if (!element.__reactRoot) {
    element.__reactRoot = createRoot(element)
  }

  element.__reactRoot.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  )
}

// ── MemoryGame のマウント ──
function mountMemoryGame() {
  const el = document.getElementById("memory-game-root")
  if (!el) return

  if (!el.__reactRoot) {
    el.__reactRoot = createRoot(el)
  }

  el.__reactRoot.render(<MemoryGame />)
}

function unmountMemoryGame() {
  const el = document.getElementById("memory-game-root")
  if (!el || !el.__reactRoot) return

  el.__reactRoot.unmount()
  delete el.__reactRoot
}

// ── イベント登録（DOMContentLoadedではなくturbo:loadを使う）──
document.addEventListener("turbo:load", () => {
  mountReactApp()
  mountMemoryGame()
})

document.addEventListener("turbo:before-cache", () => {
  unmountReactApp()
  unmountMemoryGame()
})

