import React from "react"
import { createRoot } from "react-dom/client"
import App from "./App"

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

function unmountReactApp() {
  const element = document.getElementById("react-root")
  if (!element || !element.__reactRoot) return

  element.__reactRoot.unmount()
  delete element.__reactRoot
}

document.addEventListener("turbo:load", mountReactApp)
document.addEventListener("turbo:before-cache", unmountReactApp)
