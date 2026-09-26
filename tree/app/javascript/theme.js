// Dark is the default (no attribute); light sets data-theme="light" on <html>
// and is remembered in localStorage. The inline script in the layout's <head>
// restores it before first paint.
const toggle = document.querySelector('[data-action="toggle-theme"]')

if (toggle) {
  toggle.addEventListener("click", () => {
    const root = document.documentElement
    const light = root.dataset.theme !== "light"

    if (light) {
      root.dataset.theme = "light"
    } else {
      delete root.dataset.theme
    }

    try {
      light ? localStorage.setItem("theme", "light") : localStorage.removeItem("theme")
    } catch (e) {}
  })
}
