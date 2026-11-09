(() => {
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const clamp = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v));
  const lerp = (a, b, t) => a + (b - a) * t;
  const ease = t => 1 - Math.pow(1 - t, 3);
  const seg = (p, a, b) => ease(clamp((p - a) / (b - a)));
  const pad = n => String(n).padStart(2, "0");

  /* ---------- nav ---------- */
  const nav = $("#nav");
  const onNav = () => nav.classList.toggle("scrolled", scrollY > 20);
  addEventListener("scroll", onNav, { passive: true }); onNav();

  /* ---------- date + clock (matches the visitor's day) ---------- */
  const now = new Date();
  const dateStr = now.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" });
  const h = now.getHours();
  $("#tsDate").textContent = dateStr;
  $("#lockDate").textContent = dateStr;
  $("#tsHello").textContent = h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
  const tickClock = () => {
    const d = new Date();
    const t = `${d.getHours() % 12 || 12}:${pad(d.getMinutes())}`;
    $("#clock").textContent = t; $("#lockClock").textContent = t;
  };
  tickClock(); setInterval(tickClock, 10000);

  /* ---------- reveal ---------- */
  const io = new IntersectionObserver(es => es.forEach(e => {
    if (!e.isIntersecting) return;
    e.target.classList.add("in");
    io.unobserve(e.target);
    onReveal(e.target);
  }), { threshold: .14, rootMargin: "0px 0px -6% 0px" });
  $$(".rv").forEach(el => io.observe(el));

  function onReveal(el) {
    const wv = $(".wv", el); if (wv) wv.style.strokeDashoffset = 40;
    const c = $(".count", el); if (c) countUp(c);
    if (el.hasAttribute("data-lane")) fillLane(el);
  }
  function countUp(el) {
    const to = +el.dataset.to, t0 = performance.now(), dur = reduce ? 1 : 1900;
    const step = t => { const k = ease(clamp((t - t0) / dur)); el.textContent = Math.round(to * k); if (k < 1) requestAnimationFrame(step); };
    requestAnimationFrame(step);
  }

  /* ---------- phases lanes ---------- */
  $$("[data-dots]").forEach(d => { for (let i = 0; i < +d.dataset.dots; i++) d.appendChild(document.createElement("i")); });
  function fillLane(lane) {
    const d = $("[data-dots]", lane), m = $("[data-moons]", lane);
    const items = d ? $$("i", d) : $$("span", m);
    const fill = d ? +d.dataset.fill : items.length;
    items.slice(0, fill).forEach((it, i) => setTimeout(() => it.classList.add("f"), reduce ? 0 : 300 + i * (d ? 45 : 110)));
    if (d && d.dataset.cur) setTimeout(() => items[fill] && items[fill].classList.add("cur"), reduce ? 0 : 300 + fill * 45 + 120);
  }

  /* ---------- hero: live Today screen ---------- */
  const hero = $("#hero"), ts = $("#ts"), cta = $("#cta"), tap = $("#tap"), island = $("#heroIsland");
  const C = 753.98, GOAL = 22 * 3600, BUDGET = 2 * 3600;
  const st = { out: false, worn: 20 * 3600 + 48, outSec: 0, used: 70 * 60, breaks: 2 };
  const ringVal = $("#ringVal"), ringT = $("#ringT"), ringLbl = $("#ringLbl"), pill = $("#tsPill"), islandT = $("#islandT"), miniVal = $("#miniVal"), tlSub = $("#tlSub"), tlNow = $("#tlNow");
  const fmtHMS = s => `${pad(Math.floor(s / 3600))}:${pad(Math.floor(s / 60) % 60)}:${pad(s % 60)}`;
  const fmtMS = s => `${Math.floor(s / 60)}:${pad(s % 60)}`;
  const hm = s => { const m = Math.round(s / 60); return m >= 60 ? `${Math.floor(m / 60)}h ${m % 60}m` : `${m}m`; };
  function render() {
    const left = Math.max(0, BUDGET - st.used);
    if (st.out) {
      ringT.textContent = fmtMS(st.outSec);
      ringVal.style.strokeDashoffset = C * (1 - clamp(st.used / BUDGET));
      pill.textContent = `${hm(left)} of out-time left`;
      islandT.textContent = fmtMS(st.outSec);
      miniVal.style.strokeDashoffset = 44 * (1 - clamp(st.used / BUDGET));
    } else {
      ringT.textContent = fmtHMS(st.worn);
      ringVal.style.strokeDashoffset = C * (1 - clamp(st.worn / GOAL));
      pill.textContent = `Aligners in · ${hm(left)} out-time left`;
    }
    tlSub.textContent = `${st.breaks} breaks · ${hm(st.used)} out`;
  }
  function setOut(v) {
    st.out = v;
    if (v) { st.outSec = 0; st.used = 70 * 60; st.breaks = 3; }
    ts.classList.toggle("out", v);
    hero.classList.toggle("out", v);
    island.classList.toggle("live", v);
    ringLbl.textContent = v ? "OUT FOR" : "WORN TODAY";
    tlNow.style.opacity = v ? 1 : 0;
    render();
  }
  function press(then) {
    tap.classList.remove("go"); void tap.offsetWidth; tap.classList.add("go");
    setTimeout(() => cta.classList.add("press"), 180);
    setTimeout(() => { cta.classList.remove("press"); then(); }, 400);
  }
  render();
  if (!reduce) {
    let heroVisible = true, phaseT = 0, last = performance.now(), acc = 0;
    new IntersectionObserver(([e]) => heroVisible = e.isIntersecting).observe(hero);
    const loop = t => {
      const dt = Math.min(100, t - last); last = t;
      if (heroVisible && !document.hidden) {
        phaseT += dt; acc += dt;
        if (st.out) {
          while (acc >= 100) { acc -= 100; st.outSec += 3; st.used += 3; }
          if (phaseT > 6200) { phaseT = -99999; press(() => { setOut(false); phaseT = 0; }); }
        } else {
          while (acc >= 1000) { acc -= 1000; st.worn += 1; }
          if (phaseT > 4200) { phaseT = -99999; press(() => { setOut(true); phaseT = 0; }); }
        }
        render();
      }
      requestAnimationFrame(loop);
    };
    requestAnimationFrame(loop);
  }

  /* ---------- story: sticky phone follows the steps ---------- */
  const imgs = $$("#storyScreen img"), dots = $$("#storyDots i"), halo = $("#storyHalo");
  const steps = $$(".step");
  const sio = new IntersectionObserver(es => es.forEach(e => {
    if (!e.isIntersecting) return;
    const i = +e.target.dataset.step;
    steps.forEach(s => s.classList.toggle("active", s === e.target));
    imgs.forEach(im => im.classList.toggle("on", +im.dataset.i === i));
    dots.forEach((d, k) => d.classList.toggle("on", k === i));
    halo.style.setProperty("--hc", e.target.dataset.c);
  }), { rootMargin: "-48% 0px -48% 0px" });
  steps.forEach(s => sio.observe(s));
  steps[0].classList.add("active");

  /* ---------- Dynamic Island: scroll-driven morph ---------- */
  const di = $("#island"), lock = $("#lock"), bi = $("#bigIsland"), card = $(".la-card", lock), head = $(".di-head"), caps = $$("#diCaps p");
  const S = { idle: [168, 50, 25], compact: [300, 50, 25], expanded: [496, 236, 60] };
  const mix = (a, b, t) => a.map((v, i) => lerp(v, b[i], t));
  let liveOut = 14 * 60 + 30;
  setInterval(() => { liveOut++; $$("[data-live]").forEach(el => el.textContent = fmtMS(liveOut)); }, 1000);
  let ticking = false;
  function diFrame() {
    ticking = false;
    const r = di.getBoundingClientRect(), vh = innerHeight;
    const p = clamp(-r.top / (r.height - vh));
    let dims, co = 0, eo = 0;
    if (p < .26) { const t = seg(p, .12, .24); dims = mix(S.idle, S.compact, t); co = clamp((t - .5) * 2); }
    else if (p < .62) { const t = seg(p, .40, .52); dims = mix(S.compact, S.expanded, t); co = clamp(1 - t * 3); eo = clamp((t - .55) / .45); }
    else { const t = seg(p, .62, .72); dims = mix(S.expanded, S.compact, t); eo = clamp(1 - t * 3); co = clamp((t - .55) / .45); }
    bi.style.setProperty("--w", dims[0] + "px");
    bi.style.setProperty("--h", dims[1] + "px");
    bi.style.setProperty("--r", dims[2] + "px");
    bi.style.setProperty("--co", co);
    bi.style.setProperty("--eo", eo);
    const lo = seg(p, .72, .84);
    card.style.setProperty("--lo", lo);
    const s = parseFloat(getComputedStyle(lock).getPropertyValue("--s")) || 1;
    const rise = seg(p, .06, .30);
    lock.style.transform = `translateX(-50%) translateY(${-rise * 220 * s}px) scale(${s})`;
    head.style.opacity = 1 - seg(p, .02, .12);
    head.style.transform = `translateY(${-seg(p, .02, .12) * 40}px)`;
    const ci = p < .44 ? 0 : p < .7 ? 1 : 2;
    caps.forEach((c, i) => c.classList.toggle("on", i === ci && p > .1));
  }
  const onDi = () => { if (!ticking) { ticking = true; requestAnimationFrame(diFrame); } };
  addEventListener("scroll", onDi, { passive: true });
  addEventListener("resize", onDi);
  diFrame();

  /* ---------- Control Center toggle flips now and then ---------- */
  const ctl = $("#ctl");
  if (ctl && !reduce) setInterval(() => ctl.classList.toggle("on"), 2600);
})();
