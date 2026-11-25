// The hero: links drift outward along slowly turning spiral arms, light
// pulses run along the arms, the cursor nudges tiles aside and a click sends
// a ripple. Hovering a tile stops it and puts a real link over it.
//
// The tiles come from the link list on the page (a.row), so there's nothing
// to configure here. Drawn on a 2D canvas; no library.
const hero = document.querySelector("[data-spiral]")

if (hero) start(hero)

function start(hero) {
  const canvas = hero.querySelector(".hero-field")
  const ctx = canvas.getContext("2d")
  const hit = hero.querySelector(".hero-hit")
  const tip = hero.querySelector(".hero-tip")
  const readout = hero.querySelector("[data-readout]")
  const copy = hero.querySelector(".hero-copy-inner")
  const root = document.documentElement
  const reduce = matchMedia("(prefers-reduced-motion: reduce)")

  const links = [ ...document.querySelectorAll("#links a.row") ].map((a) => ({
    href: a.getAttribute("href"),
    target: a.getAttribute("target"),
    title: a.querySelector(".title")?.textContent.trim() ?? "",
    domain: a.querySelector(".domain")?.textContent.trim() ?? "",
    svg: a.querySelector(".tile svg")
  }))

  splitName(hero.querySelector(".mark"))
  document.body.classList.add("intro")

  // ---- colors and icon images, redone when the theme changes ----
  let colors = {}
  let icons = new Map()
  function readColors() {
    const style = getComputedStyle(root)
    for (const name of [ "bg", "surface", "ink", "muted", "line", "pulse" ]) {
      colors[name] = style.getPropertyValue(`--${name}`).trim()
    }
    icons = new Map()
  }
  function iconImage(svg, color) {
    const key = svg.outerHTML + color
    if (!icons.has(key)) {
      const copy = svg.cloneNode(true)
      copy.setAttribute("xmlns", "http://www.w3.org/2000/svg")
      copy.setAttribute("width", "96")
      copy.setAttribute("height", "96")
      copy.setAttribute("stroke", color)
      copy.setAttribute("stroke-width", "1.6")
      const image = new Image()
      image.src = "data:image/svg+xml;charset=utf-8," + encodeURIComponent(new XMLSerializer().serializeToString(copy))
      icons.set(key, image)
    }
    return icons.get(key)
  }
  readColors()
  new MutationObserver(() => { readColors(); if (reduce.matches) still() })
    .observe(root, { attributes: true, attributeFilter: [ "data-theme" ] })

  // ---- layout ----
  let L = {}
  let state = []
  let hotId = -1
  let dpr = 1

  function layout() {
    const W = hero.clientWidth, H = hero.clientHeight
    dpr = Math.min(2, window.devicePixelRatio || 1)
    canvas.width = Math.round(W * dpr)
    canvas.height = Math.round(H * dpr)

    const mobile = W < 640
    // On a narrow screen a round spiral spills off the sides, so the spiral
    // is drawn in a square of the hero's height and squeezed to its width.
    const sx = mobile ? W / H : 1
    const half = mobile ? Math.hypot(H, H) / 2 : Math.hypot(W, H) / 2
    const arms = mobile ? 2 : 3
    const thetaMax = (mobile ? 1.15 : 1.4) * Math.PI * 2
    const rMax = 0.88 * half
    const b = rMax / thetaMax
    const tileMax = mobile ? clamp(W * 0.15, 44, 64) : clamp(H * 0.135, 56, 104)
    const thetaBirth = 0.2 * thetaMax
    const thetaExit = (half + 1.5 * tileMax) / b

    const armList = []
    const ticks = new Path2D()
    for (let a = 0; a < arms; a++) {
      const off = a * Math.PI * 2 / arms
      const points = []
      const path = new Path2D()
      for (let n = 0; n <= 180; n++) {
        const th = 0.3 * thetaBirth + n / 180 * (thetaExit - 0.3 * thetaBirth)
        const x = b * th * Math.cos(th + off), y = b * th * Math.sin(th + off)
        points.push(x, y, n / 180)
        n ? path.lineTo(x, y) : path.moveTo(x, y)
      }
      armList.push({ off, points, path })
      for (let k = 0; k < 9; k++) {
        const th = thetaMax * (0.45 + 0.55 * (k + 0.5) / 9), r = b * th
        const c = Math.cos(th + off), s = Math.sin(th + off)
        ticks.moveTo((r - 6) * c, (r - 6) * s)
        ticks.lineTo((r + 6) * c, (r + 6) * s)
      }
    }

    const perArm = links.length ? (mobile ? 4 : 6) : 0
    if (state.length !== arms * perArm) {
      state = Array.from({ length: arms * perArm }, () => ({ clock: 0, dx: 0, dy: 0, spinLock: 0 }))
      hotId = -1
    }

    const box = copy.getBoundingClientRect()
    L = {
      W, H, cx: W / 2, cy: H / 2, half, sx, arms, perArm, b, rMax, thetaBirth, thetaExit,
      tileMax, tileMin: tileMax * 0.45, armList, ticks,
      circR: Math.min(W, H) * (mobile ? 0.42 : 0.36),
      keepW: Math.max(60, box.width / 2 * 0.95), keepH: Math.max(60, box.height / 2 * 0.85)
    }
  }

  // ---- pointer and ripples ----
  const pointer = { x: -9999, y: -9999, k: 0, on: false }
  let ripples = []

  hero.addEventListener("pointermove", (event) => {
    const rect = hero.getBoundingClientRect()
    pointer.x = event.clientX - rect.left - L.cx
    pointer.y = event.clientY - rect.top - L.cy
    pointer.on = event.pointerType === "mouse" || event.pointerType === "pen"
  })
  hero.addEventListener("pointerleave", () => { pointer.on = false })
  hero.addEventListener("pointerdown", (event) => {
    if (reduce.matches || event.target.closest(".ctas")) return
    const rect = hero.getBoundingClientRect()
    ripples.push({ x: event.clientX - rect.left - L.cx, y: event.clientY - rect.top - L.cy, t: performance.now() })
  })

  // Touch has no hover, so a tap on a tile opens its link directly. A drag
  // that scrolls the page ends in pointercancel, not pointerup.
  let lastTiles = []
  let tap = null
  hero.addEventListener("pointerdown", (event) => {
    tap = event.pointerType === "touch" ? { x: event.clientX, y: event.clientY, t: performance.now() } : null
  })
  hero.addEventListener("pointercancel", () => { tap = null })
  hero.addEventListener("pointerup", (event) => {
    if (!tap || event.target.closest("a, button")) return
    const moved = Math.hypot(event.clientX - tap.x, event.clientY - tap.y)
    const quick = performance.now() - tap.t < 600
    tap = null
    if (moved > 12 || !quick) return
    const rect = hero.getBoundingClientRect()
    const x = event.clientX - rect.left - L.cx, y = event.clientY - rect.top - L.cy
    for (let i = lastTiles.length - 1; i >= 0; i--) {
      const tile = lastTiles[i], h = tile.s / 2 + 8
      if (tile.a < 0.3 || Math.abs(x - tile.x) > h || Math.abs(y - tile.y) > h) continue
      if (tile.link.target === "_blank") window.open(tile.link.href, "_blank", "noopener")
      else location.href = tile.link.href
      return
    }
  })

  // ---- drawing ----
  const startText = readout?.textContent ?? ""
  let lastT = 0
  let lastReadout = startText

  function draw(t) {
    const dt = Math.min(0.05, Math.max(0, t - lastT))
    lastT = t
    const now = performance.now()
    const dark = root.dataset.theme !== "light"

    ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    ctx.clearRect(0, 0, L.W, L.H)
    ctx.translate(L.cx, L.cy)

    const waveR = (1 - Math.pow(1 - Math.min(1, t / 2.2), 3)) * (L.half + 260)
    const spin = t * 0.022
    pointer.k += ((pointer.on ? 1 : 0) - pointer.k) * 0.08

    // arms, ticks, pulses and the dashed ring
    // The spiral is turned, then squeezed by sx. Paths are transformed
    // before stroking so the lines keep an even width.
    const cs = Math.cos(spin), sn = Math.sin(spin)
    const toScreen = (x, y) => [ (x * cs - y * sn) * L.sx, x * sn + y * cs ]
    const matrix = new DOMMatrix([ cs * L.sx, sn, -sn * L.sx, cs, 0, 0 ])
    const squeezed = (path) => { const out = new Path2D(); out.addPath(path, matrix); return out }

    ctx.save()
    ctx.beginPath()
    ctx.ellipse(0, 0, Math.max(1, waveR * L.sx), Math.max(1, waveR), 0, 0, Math.PI * 2)
    ctx.clip()
    ctx.lineWidth = 1
    ctx.strokeStyle = colors.line
    for (const arm of L.armList) ctx.stroke(squeezed(arm.path))
    ctx.globalAlpha = 0.9
    ctx.strokeStyle = colors.muted
    ctx.stroke(squeezed(L.ticks))

    ctx.strokeStyle = colors.pulse
    ctx.lineCap = "round"
    L.armList.forEach((arm, ai) => {
      const p = arm.points
      for (let i = 0; i < p.length - 3; i += 3) {
        const aT = p[i + 2]
        const s = fract(aT * 2 - t * 0.2 + ai * 0.618) - 0.5
        const sig = 0.035 * (s < 0 ? 1.7 : 0.55)
        const g = Math.exp(-0.5 * (s / sig) ** 2) * smooth(0.04, 0.14, aT)
        if (g < 0.03) continue
        ctx.globalAlpha = g * (dark ? 1 : 0.85)
        ctx.lineWidth = 1 + 3 * g
        ctx.beginPath()
        ctx.moveTo(...toScreen(p[i], p[i + 1]))
        ctx.lineTo(...toScreen(p[i + 3], p[i + 4]))
        ctx.stroke()
      }
    })
    ctx.globalAlpha = 1
    ctx.lineCap = "butt"
    ctx.rotate(-spin * 2)
    ctx.setLineDash([ 2, 9 ])
    ctx.strokeStyle = colors.muted
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.arc(0, 0, L.circR, 0, Math.PI * 2)
    ctx.stroke()
    ctx.setLineDash([])
    ctx.restore()

    ripples = ripples.filter((r) => now - r.t < 1600)
    for (const r of ripples) {
      const age = (now - r.t) / 1600
      ctx.globalAlpha = (1 - age) * 0.8
      ctx.strokeStyle = colors.pulse
      ctx.lineWidth = 1.5
      ctx.beginPath()
      ctx.arc(r.x, r.y, age * 900, 0, Math.PI * 2)
      ctx.stroke()
    }
    ctx.globalAlpha = 1

    // tiles
    const tiles = []
    for (let a = 0; a < L.arms; a++) {
      for (let k = 0; k < L.perArm; k++) {
        const id = a * L.perArm + k
        const st = state[id]
        const isHot = id === hotId
        if (!isHot) st.clock += dt * 0.016 // the hovered tile stops drifting
        const spinNow = isHot ? st.spinLock : spin // ...and stops turning

        const u = fract(k / L.perArm + a * 0.13 + st.clock)
        const th = L.thetaBirth + u * (L.thetaExit - L.thetaBirth)
        const r = L.b * th
        const angle = th + L.armList[a].off + spinNow
        const bx = r * Math.cos(angle) * L.sx, by = r * Math.sin(angle)
        const size = L.tileMin + (L.tileMax - L.tileMin) * smooth(0, L.rMax, r)

        // the cursor nudges tiles aside, but never the one right under it
        let tx = 0, ty = 0
        if (!isHot && pointer.k > 0.01) {
          const dx = bx - pointer.x, dy = by - pointer.y, d = Math.hypot(dx, dy) || 1, R = 230
          if (d < R) {
            const q = d / R, f = 40 * 6.75 * q * (1 - q) * (1 - q) * pointer.k
            tx += dx / d * f
            ty += dy / d * f
          }
        }
        for (const rp of ripples) {
          const age = (now - rp.t) / 1600
          const ex = bx - rp.x, ey = by - rp.y, ed = Math.hypot(ex, ey) || 1
          const band = Math.exp(-(((ed - age * 900) / 50) ** 2)) * 26 * (1 - age)
          tx += ex / ed * band
          ty += ey / ed * band
        }
        st.dx += (tx - st.dx) * 0.14
        st.dy += (ty - st.dy) * 0.14
        const x = bx + st.dx, y = by + st.dy

        let alpha = smooth(0, 0.08, u) * clamp((waveR - r) / 160, 0, 1)
        const ex = x / L.keepW, ey = y / L.keepH
        alpha *= 0.12 + 0.88 * smooth(0.9, 1.35, ex * ex + ey * ey)
        tiles.push({ id, x, y, bx, by, s: size, a: alpha, u, link: links[id % links.length] })
      }
    }
    tiles.sort((p, q) => p.s - q.s)
    lastTiles = tiles

    // hover: keep the current tile while the cursor stays near it
    if (hotId >= 0) {
      const current = tiles.find((tile) => tile.id === hotId)
      const reach = current && current.s * 0.57 + 12
      const keep = current && pointer.on && Math.abs(pointer.x - current.x) < reach && Math.abs(pointer.y - current.y) < reach
      if (!keep) {
        if (current) { // hand the tile back to the field without a jump
          const st = state[hotId]
          const [ ux, uy ] = rotate(current.bx / L.sx, current.by, spin - st.spinLock)
          const nx = ux * L.sx, ny = uy
          st.dx += current.bx - nx
          st.dy += current.by - ny
        }
        hotId = -1
      }
    }
    if (hotId < 0 && pointer.on) {
      for (let i = tiles.length - 1; i >= 0; i--) {
        const tile = tiles[i], h = tile.s / 2 + 2
        if (tile.a < 0.5) continue
        const overDrawn = Math.abs(pointer.x - tile.x) < h && Math.abs(pointer.y - tile.y) < h
        const overBase = Math.abs(pointer.x - tile.bx) < h && Math.abs(pointer.y - tile.by) < h
        if (overDrawn || overBase) {
          hotId = tile.id
          state[tile.id].spinLock = spin
          break
        }
      }
    }

    let hotTile = null
    for (const tile of tiles) {
      if (tile.a < 0.01) continue
      const isHot = tile.id === hotId
      const s = tile.s * (isHot ? 1.14 : 1)
      if (isHot) hotTile = tile
      ctx.globalAlpha = isHot ? 1 : tile.a
      if (tile.u < 0.16 && !isHot && !reduce.matches) ctx.filter = `blur(${((1 - tile.u / 0.16) * 5).toFixed(1)}px)`
      ctx.beginPath()
      ctx.roundRect ? ctx.roundRect(tile.x - s / 2, tile.y - s / 2, s, s, s * 0.2) : ctx.rect(tile.x - s / 2, tile.y - s / 2, s, s)
      ctx.fillStyle = isHot ? colors.ink : colors.surface
      ctx.fill()
      ctx.lineWidth = 1
      ctx.strokeStyle = isHot ? colors.ink : colors.line
      ctx.stroke()
      if (tile.link.svg) {
        const image = iconImage(tile.link.svg, isHot ? colors.bg : colors.ink)
        const is = s * 0.5
        if (image.complete && image.naturalWidth) ctx.drawImage(image, tile.x - is / 2, tile.y - is / 2, is, is)
      }
      ctx.filter = "none"
    }
    ctx.globalAlpha = 1

    showHit(hotTile)
    showReadout(hotTile)
  }

  // the real, clickable link over the hovered tile
  function showHit(tile) {
    if (!tile) {
      if (hit.classList.contains("on")) {
        hit.classList.remove("on")
        hit.dataset.id = ""
      }
      return
    }
    const size = tile.s * 1.14
    if (hit.dataset.id !== String(hotId)) {
      hit.dataset.id = hotId
      hit.href = tile.link.href
      if (tile.link.target) {
        hit.target = tile.link.target
        hit.rel = "noopener"
      } else {
        hit.removeAttribute("target")
        hit.removeAttribute("rel")
      }
      tip.textContent = `${tile.link.title.toLowerCase()} ↗`
    }
    hit.style.width = `${size}px`
    hit.style.height = `${size}px`
    hit.style.transform = `translate(${(L.cx + tile.x - size / 2).toFixed(1)}px, ${(L.cy + tile.y - size / 2).toFixed(1)}px)`
    hit.classList.toggle("flip", L.cx + tile.x > L.W - 200)
    hit.classList.add("on")
  }

  // live polar readout of the cursor
  function showReadout(tile) {
    if (!readout) return
    let text = startText
    if (pointer.on) {
      const deg = (Math.atan2(-pointer.y, pointer.x) * 180 / Math.PI + 360) % 360
      text = `r ${pad(Math.hypot(pointer.x, pointer.y))} · θ ${pad(deg)}°${tile ? ` · ${tile.link.domain}` : ""}`
    }
    if (text !== lastReadout) {
      readout.textContent = text
      lastReadout = text
    }
  }

  // ---- loop: pauses off screen, in background tabs and for reduced motion ----
  let running = false
  let visible = true
  const t0 = performance.now()

  function still() { lastT = 20; draw(20) }
  // Resizing the canvas clears it, so the still frame is drawn again.
  function relayout() { layout(); if (reduce.matches) still() }
  function frame() {
    if (!visible || document.hidden || reduce.matches) { running = false; return }
    draw((performance.now() - t0) / 1000)
    requestAnimationFrame(frame)
  }
  function run() {
    if (reduce.matches) { still(); return }
    if (!running) {
      running = true
      lastT = (performance.now() - t0) / 1000
      requestAnimationFrame(frame)
    }
  }

  new IntersectionObserver((entries) => { visible = entries[0].isIntersecting; if (visible) run() }).observe(hero)
  document.addEventListener("visibilitychange", run)
  reduce.addEventListener("change", run)
  let resizeTimer
  window.addEventListener("resize", () => {
    clearTimeout(resizeTimer)
    resizeTimer = setTimeout(relayout, 120)
  })

  layout()
  document.fonts?.ready.then(relayout)
  run()
}

// Wraps each letter of the name so CSS can animate them one after another.
// The heading keeps the full name as its accessible label.
function splitName(heading) {
  if (!heading) return
  const name = heading.textContent.trim()
  heading.setAttribute("aria-label", name)
  heading.textContent = ""
  let i = 0
  name.split(/\s+/).forEach((word, w) => {
    if (w) heading.append(" ")
    const group = document.createElement("span")
    group.className = "word"
    group.setAttribute("aria-hidden", "true")
    for (const char of word) {
      const span = document.createElement("span")
      span.textContent = char
      span.style.setProperty("--i", i++)
      group.appendChild(span)
    }
    heading.appendChild(group)
  })
}

function smooth(e0, e1, x) { const t = clamp((x - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t) }
function fract(x) { return x - Math.floor(x) }
function clamp(x, lo, hi) { return Math.min(hi, Math.max(lo, x)) }
function rotate(x, y, d) { const c = Math.cos(d), s = Math.sin(d); return [ x * c - y * s, x * s + y * c ] }
function pad(n) { return String(Math.round(n)).padStart(3, "0") }
