/* =====================================================================
 * ui.jsx — Composants partagés : icônes, boutons, stepper, confettis…
 * Jeu d'icônes trait 1.8px, 24×24 (style cohérent type "line icons").
 * ===================================================================== */
const ICONS = {
  back: <path d="M15 18l-6-6 6-6" />,
  chevron: <path d="M9 18l6-6-6-6" />,
  plus: <path d="M12 5v14M5 12h14" />,
  minus: <path d="M5 12h14" />,
  check: <path d="M20 6L9 17l-5-5" />,
  trash: <><path d="M3 6h18" /><path d="M8 6V4h8v2" /><path d="M19 6l-1 14H6L5 6" /></>,
  bag: <><path d="M6 7h12l1 13H5L6 7z" /><path d="M9 7a3 3 0 016 0" /></>,
  card: <><rect x="2.5" y="5" width="19" height="14" rx="2.5" /><path d="M2.5 10h19M6.5 15h4" /></>,
  cash: <><rect x="2.5" y="6" width="19" height="12" rx="2" /><circle cx="12" cy="12" r="2.6" /><path d="M6 9.5v5M18 9.5v5" /></>,
  terminal: <><rect x="6" y="2.5" width="12" height="19" rx="2.5" /><rect x="8.5" y="5" width="7" height="4.5" rx="1" /><path d="M9 13h.01M12 13h.01M15 13h.01M9 16h.01M12 16h.01M15 16h.01" /></>,
  clock: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
  receipt: <><path d="M5 3h14v18l-3-2-2 2-2-2-2 2-2-2-3 2V3z" /><path d="M9 8h6M9 12h6" /></>,
  cup: <><path d="M4 9h13v5a5 5 0 01-5 5H9a5 5 0 01-5-5V9z" /><path d="M17 10h1.5a2.5 2.5 0 010 5H17" /><path d="M8 3c0 1.5 1.5 1.5 1.5 3M12 3c0 1.5 1.5 1.5 1.5 3" /></>,
  scooter: <><circle cx="6" cy="17" r="2.5" /><circle cx="18" cy="17" r="2.5" /><path d="M8.5 17h7M15 6h2l2.5 8.5M15 6l-3 8" /></>,
  pin: <><path d="M12 21s-7-6.2-7-11.5A7 7 0 0119 9.5C19 14.8 12 21 12 21z" /><circle cx="12" cy="9.5" r="2.5" /></>,
  layers: <><path d="M12 3l9 5-9 5-9-5 9-5z" /><path d="M3 13l9 5 9-5" /></>,
  grid: <><rect x="3.5" y="3.5" width="7" height="7" rx="1.5" /><rect x="13.5" y="3.5" width="7" height="7" rx="1.5" /><rect x="3.5" y="13.5" width="7" height="7" rx="1.5" /><rect x="13.5" y="13.5" width="7" height="7" rx="1.5" /></>,
  bell: <><path d="M6 16V11a6 6 0 0112 0v5l1.5 2h-15L6 16z" /><path d="M10 20.5a2 2 0 004 0" /></>,
  star: <path d="M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8-4.3-4.1 5.9-.9L12 3.5z" />,
  qr: <><rect x="4" y="4" width="6" height="6" rx="1" /><rect x="14" y="4" width="6" height="6" rx="1" /><rect x="4" y="14" width="6" height="6" rx="1" /><path d="M14 14h2v2h-2zM18 18h2v2h-2zM14 18h2M18 14h2" /></>,
  alert: <><circle cx="12" cy="12" r="9" /><path d="M12 7.5v5.5M12 16.5h.01" /></>,
  refresh: <><path d="M20 11a8 8 0 10-2.3 5.7" /><path d="M20 4v7h-7" /></>,
  sparkle: <path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3z" />,
  globe: <><circle cx="12" cy="12" r="9" /><path d="M3 12h18M12 3c2.5 2.7 2.5 15.3 0 18M12 3c-2.5 2.7-2.5 15.3 0 18" /></>
};

function Icon({ name, size = 22, stroke = 1.8, fill = "none", className, style }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke="currentColor" strokeWidth={stroke}
      strokeLinecap="round" strokeLinejoin="round" className={className} style={style} aria-hidden="true">
      {ICONS[name]}
    </svg>
  );
}

/** Bouton avec état de chargement. */
function Button({ variant = "primary", loading, children, className = "", ...rest }) {
  return (
    <button className={`btn btn-${variant} ${className}`} disabled={loading || rest.disabled} {...rest}>
      {loading ? <span className="spinner" aria-hidden="true" /> : null}
      {children}
    </button>
  );
}

/** Barre supérieure générique. */
function TopBar({ title, onBack, right }) {
  const { t } = useStore();
  return (
    <div className="topbar">
      {onBack && (
        <button className="icon-btn" onClick={onBack} aria-label={t("common.back")}>
          <Icon name="back" className="flip-rtl" />
        </button>
      )}
      <h2>{title}</h2>
      {right}
    </div>
  );
}

function TableChip() {
  const { state, t } = useStore();
  return <span className="chip"><span className="dot" />{t("common.table", { n: state.table })}</span>;
}

/** Stepper quantité +/- avec animation de chiffre. */
function QtyStepper({ qty, onInc, onDec, labelInc, labelDec, max = 20 }) {
  return (
    <div className={`stepper ${qty > 0 ? "active" : ""}`}>
      <button onClick={onDec} aria-label={labelDec}><Icon name={qty === 1 ? "trash" : "minus"} size={18} stroke={2.2} /></button>
      <span className="q num" aria-live="polite"><span key={qty} className="q-anim">{qty}</span></span>
      <button onClick={onInc} disabled={qty >= max} aria-label={labelInc}><Icon name="plus" size={18} stroke={2.2} /></button>
    </div>
  );
}

/** Image produit avec fallback placeholder rayé. */
function ProductImage({ src, alt }) {
  const [err, setErr] = useState(false);
  if (!src || err) return <div className="ph">photo produit<br />{alt}</div>;
  return <img src={src} alt={alt} loading="lazy" onError={() => setErr(true)} />;
}

/** Confettis canvas (couleurs de la marque). */
function Confetti({ run = true }) {
  const ref = useRef(null);
  useEffect(() => {
    if (!run || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const c = ref.current, ctx = c.getContext("2d");
    const dpr = window.devicePixelRatio || 1;
    const W = c.offsetWidth, H = c.offsetHeight;
    c.width = W * dpr; c.height = H * dpr; ctx.scale(dpr, dpr);
    const colors = ["#c98a4b", "#24180f", "#e9c9a0", "#7fa58a", "#fbf7f1"];
    const parts = Array.from({ length: 140 }, (_, i) => ({
      x: W / 2 + (Math.random() - .5) * 60, y: H * .32,
      vx: (Math.random() - .5) * 11, vy: -Math.random() * 13 - 4,
      w: 6 + Math.random() * 6, h: 8 + Math.random() * 8,
      r: Math.random() * Math.PI, vr: (Math.random() - .5) * .3,
      c: colors[i % colors.length], shape: Math.random() > .7 ? "c" : "r"
    }));
    let raf, frame = 0;
    const loop = () => {
      frame++;
      ctx.clearRect(0, 0, W, H);
      parts.forEach((p) => {
        p.vy += .28; p.vx *= .99; p.x += p.vx; p.y += p.vy; p.r += p.vr;
        ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.r); ctx.fillStyle = p.c;
        ctx.globalAlpha = Math.max(0, 1 - frame / 200);
        if (p.shape === "c") { ctx.beginPath(); ctx.arc(0, 0, p.w / 2, 0, 7); ctx.fill(); }
        else ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h * Math.abs(Math.cos(p.r * 2)));
        ctx.restore();
      });
      if (frame < 200) raf = requestAnimationFrame(loop);
    };
    loop();
    return () => cancelAnimationFrame(raf);
  }, [run]);
  return <canvas ref={ref} className="confetti" aria-hidden="true" />;
}

/** Bannière d'erreur réseau. */
function NetBanner({ show }) {
  const { t } = useStore();
  if (!show) return null;
  return <div className="net-banner" role="alert">{t("net.unstable")}</div>;
}

/** Robot dessiné en formes CSS simples. */
function Robot({ moving, size = 1 }) {
  return (
    <div className={`bot ${moving ? "moving" : ""}`} style={{ transform: `scale(${size})` }} aria-hidden="true">
      <div className="antenna" />
      <div className="head"><div className="visor"><span className="eye" /><span className="eye" /></div></div>
      <div className="body"><div className="tray"><Icon name="cup" size={14} stroke={2.2} /></div></div>
      <div className="wheel l" /><div className="wheel r" />
    </div>
  );
}

Object.assign(window, { Icon, Button, TopBar, TableChip, QtyStepper, ProductImage, Confetti, NetBanner, Robot });
