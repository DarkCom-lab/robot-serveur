/* =====================================================================
 * Écran 5 — Attente : chronomètre auto + étapes Reçue → Préparation → Livraison
 * ===================================================================== */

/** Chiffres du chrono qui "tombent" à chaque changement. */
function ClockDigits({ sec }) {
  const s = fmtClock(sec);
  return (
    <span className="t num" aria-label={s}>
      {s.split("").map((ch, i) => ch === ":" ? <span key={i}>:</span> :
        <span key={i + "-" + ch} className="digit tickd">{ch}</span>)}
    </span>
  );
}

function TimerRing({ sec, label, sub }) {
  const R = 104, C = 2 * Math.PI * R;
  const frac = (sec % 60) / 60;
  return (
    <div className="timer">
      <span className="pulse-ring" />
      <svg viewBox="0 0 230 230" width="230" height="230">
        <circle className="track" cx="115" cy="115" r={R} fill="none" strokeWidth="8" />
        <circle className="prog" cx="115" cy="115" r={R} fill="none" strokeWidth="8" strokeLinecap="round"
          strokeDasharray={C} strokeDashoffset={C * (1 - frac)} />
      </svg>
      <div className="timer-inner">
        <div>
          <small>{label}</small>
          <ClockDigits sec={sec} />
          <div className="order-chip">{sub}</div>
        </div>
      </div>
    </div>
  );
}

/** Liste d'étapes réutilisée (attente + réception). */
function OrderSteps() {
  const { state, t } = useStore();
  const ts = state.timestamps;
  const s = state.status;
  const deliveringReached = ["robot_picked", "delivering", "delivered", "completed"].includes(s);
  const preparingReached = deliveringReached || state.step === "preparing";
  const hhmm = (v) => v ? new Date(v).toLocaleTimeString(state.lang === "ar" ? "ar-MA" : "fr-FR", { hour: "2-digit", minute: "2-digit" }) : "";

  const steps = [
    { key: "received", icon: "receipt", done: true, current: false, time: ts.received },
    { key: "preparing", icon: "cup", done: deliveringReached, current: preparingReached && !deliveringReached, time: ts.preparing },
    { key: "delivering", icon: "scooter", done: s === "delivered" || s === "completed", current: deliveringReached && s !== "delivered" && s !== "completed", time: ts.robot_picked }
  ];
  // "Reçue" est en cours tant que la préparation n'a pas commencé
  if (!preparingReached) { steps[0].done = false; steps[0].current = true; }

  return (
    <div className="card steps">
      {steps.map((st) => (
        <div key={st.key} className={`step ${st.done ? "done" : ""} ${st.current ? "current" : ""}`}>
          <span className="bullet"><Icon name={st.done ? "check" : st.icon} size={18} stroke={st.done ? 2.6 : 1.9} /></span>
          <div>
            <h4>{t("steps." + st.key)}</h4>
            <p>{t("steps." + st.key + "Desc")}{st.current && <span className="dots" style={{ marginInlineStart: 4 }}><i /><i /><i /></span>}</p>
          </div>
          <span className="time num">{(st.done || st.current) ? hhmm(st.time) : ""}</span>
        </div>
      ))}
    </div>
  );
}

function MiniSummary() {
  const { state, t, loc, fmtPrice } = useStore();
  const o = state.order;
  if (!o) return null;
  return (
    <div className="card mini-summary">
      <div className="hd">
        <span>{t("waiting.summary")}</span>
        <span className="pm"><Icon name={state.paymentMethod === "card" ? "card" : "cash"} size={14} />{t("pay." + state.paymentMethod)}</span>
      </div>
      <div style={{ marginTop: 8 }}>
        {o.items.map((it) => (
          <div key={it.id} className="it"><span><span className="num">{it.qty}×</span> {loc(it.name)}</span><span className="num">{fmtPrice(it.price * it.qty)}</span></div>
        ))}
        <div className="it" style={{ color: "var(--ink)", fontWeight: 800, borderTop: "1px dashed var(--line-2)", marginTop: 6, paddingTop: 8 }}>
          <span>{t("review.total")}</span><span className="num">{fmtPrice(o.total)}</span>
        </div>
      </div>
    </div>
  );
}

function WaitingScreen() {
  const { state, t } = useStore();
  const sec = useElapsed(state.order?.createdAt);
  return (
    <div className="screen">
      <TopBar title="" right={<TableChip />} />
      <div className="scroll">
        <div className="wait-wrap">
          <h1 className="wait-title rise">{t("waiting.title")}</h1>
          <div className="pop" style={{ "--d": "120ms" }}>
            <TimerRing sec={sec} label={t("waiting.elapsed")} sub={t("waiting.order", { n: "#" + (state.order?.number ?? "") })} />
          </div>
          <div className="rise" style={{ "--i": 3, width: "100%" }}><OrderSteps /></div>
          <div className="rise" style={{ "--i": 4, width: "100%" }}><MiniSummary /></div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { WaitingScreen, OrderSteps, MiniSummary, ClockDigits });
