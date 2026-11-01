/* =====================================================================
 * Écran 6 — Livraison par robot : étage + zone, plan de salle animé
 * ===================================================================== */

/** Trajets du bar vers chaque zone (viewBox 300×150). */
const ROUTES = {
  A: "M58 75 H 92 V 44 H 146",
  B: "M58 75 H 196 V 106 H 246"
};

/** Valeur qui glisse en douceur vers la cible (le polling est par à-coups). */
function useSmooth(target, speed = 0.06) {
  const [v, setV] = useState(target);
  const cur = useRef(target);
  useEffect(() => {
    let raf;
    const loop = () => {
      const d = target - cur.current;
      if (Math.abs(d) < 0.0008) { cur.current = target; setV(target); return; }
      cur.current += d * speed; setV(cur.current);
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, [target]);
  return v;
}

function FloorPlan({ zone, progress, floor }) {
  const { t } = useStore();
  const pathRef = useRef(null);
  const [pt, setPt] = useState({ x: 58, y: 75 });
  const [len, setLen] = useState(0);

  useEffect(() => { if (pathRef.current) setLen(pathRef.current.getTotalLength()); }, [zone]);
  useEffect(() => {
    if (!pathRef.current || !len) return;
    const p = pathRef.current.getPointAtLength(len * Math.min(1, Math.max(0, progress)));
    setPt({ x: p.x, y: p.y });
  }, [progress, len]);

  const tables = (x0) => [[x0 + 18, 26], [x0 + 52, 26], [x0 + 18, 116], [x0 + 52, 116]];

  return (
    <div className="plan">
      <div className="plan-hd">
        <span style={{ display: "flex", alignItems: "center", gap: 6 }}><Icon name="layers" size={14} />{t("robot.floor")} {floor ?? "–"}</span>
        <span className="num">{t("robot.progress", { p: Math.round(progress * 100) })}</span>
      </div>
      <svg className="plan-svg" viewBox="0 0 300 150" role="img" aria-label={t("robot.title")}>
        <rect className="floor" x="0" y="0" width="300" height="150" rx="14" />
        {/* Bar */}
        <rect className="bar" x="10" y="40" width="40" height="70" rx="8" />
        <text className="barlabel" x="30" y="79" textAnchor="middle">{t("robot.bar").toUpperCase()}</text>
        {/* Zones */}
        {["A", "B"].map((z, i) => {
          const x = i === 0 ? 102 : 202;
          const target = z === zone;
          return (
            <g key={z}>
              <rect className={`zone ${target ? "target" : ""}`} x={x - 8} y="10" width="92" height="130" rx="10" />
              {tables(x).map(([tx, ty], k) => <rect key={k} className="tbl" x={tx - 9} y={ty - 7} width="18" height="14" rx="4" />)}
              <text className={`zlabel ${target ? "target" : ""}`} x={x + 38} y="80" textAnchor="middle">{z}</text>
            </g>
          );
        })}
        {/* Trajet */}
        {zone && (
          <>
            <path className="route" d={ROUTES[zone]} />
            <path ref={pathRef} className="route-done" d={ROUTES[zone]}
              strokeDasharray={len} strokeDashoffset={len * (1 - progress)} />
            <circle cx={pt.x} cy={pt.y} r="13" fill="oklch(0.68 0.13 58 / .25)">
              <animate attributeName="r" values="9;15;9" dur="1.6s" repeatCount="indefinite" />
            </circle>
            <circle cx={pt.x} cy={pt.y} r="7.5" fill="#fbf7f1" stroke="oklch(0.68 0.13 58)" strokeWidth="3" />
          </>
        )}
      </svg>
      <div className="progress-line">
        <Icon name="scooter" size={16} />
        <span className="bar"><i style={{ width: `${progress * 100}%` }} /></span>
        <Icon name="pin" size={16} />
      </div>
    </div>
  );
}

function RobotScreen() {
  const { state, t } = useStore();
  const loc = state.location;
  const picked = state.status === "robot_picked";
  const progress = useSmooth(picked ? 0 : state.robotProgress || 0);
  const sec = useElapsed(state.order?.createdAt);

  return (
    <div className="screen robot-screen">
      <TopBar title="" right={<span className="chip num"><Icon name="clock" size={14} />{fmtClock(sec)}</span>} />
      <div className="scroll">
        <div className="robot-head rise">
          <span className="eyebrow"><span className="live" />{t("robot.badge")} · {t("common.table", { n: state.table })}</span>
          <h1>{t("robot.title")}</h1>
        </div>

        <div className="bot-stage pop" style={{ "--d": "150ms" }}>
          <span className="shadow" />
          <Robot moving={!picked} />
        </div>
        <p className="robot-msg" aria-live="polite">
          {picked || !loc ? t("robot.picked") : t("robot.hint", { f: loc.floor, z: loc.zone })}
        </p>

        <div className="loc-row">
          <div className="loc rise" style={{ "--i": 2 }}>
            <Icon name="layers" size={18} className="ic" />
            <small>{t("robot.floor")}</small>
            <strong className="num">{loc ? loc.floor : <span className="dots"><i /><i /><i /></span>}</strong>
          </div>
          <div className="loc hl rise" style={{ "--i": 3 }}>
            <Icon name="grid" size={18} className="ic" />
            <small>{t("robot.zone")}</small>
            <strong>{loc ? loc.zone : <span className="dots"><i /><i /><i /></span>}</strong>
          </div>
        </div>

        <div className="rise" style={{ "--i": 4 }}>
          <FloorPlan zone={loc?.zone} floor={loc?.floor} progress={progress} />
        </div>
        <div style={{ height: 24 }} />
      </div>
    </div>
  );
}
window.RobotScreen = RobotScreen;
