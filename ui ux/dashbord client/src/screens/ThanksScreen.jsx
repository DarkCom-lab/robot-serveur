/* =====================================================================
 * Écran 7b — Remerciement animé + note (étoiles + tags)
 * ===================================================================== */
function ThanksScreen() {
  const { state, dispatch, t } = useStore();
  const [stars, setStars] = useState(state.rating?.stars || 0);
  const [tags, setTags] = useState(state.rating?.tags || []);
  const [sent, setSent] = useState(!!state.rating);
  const [sending, setSending] = useState(false);
  const ts = state.timestamps;
  const deliveredIn = ts.delivered && state.order ? Math.floor((ts.delivered - state.order.createdAt) / 1000) : null;

  const toggleTag = (k) => setTags((a) => (a.includes(k) ? a.filter((x) => x !== k) : [...a, k]));
  const send = async () => {
    setSending(true);
    try { await window.CafeAPI.rateOrder(state.order?.id, { stars, tags }); } catch (e) {}
    dispatch({ type: "SET_RATING", rating: { stars, tags } });
    setSent(true); setSending(false);
  };

  return (
    <div className="screen thanks">
      <Confetti />
      <div className="scroll" style={{ width: "100%" }}>
        <div style={{ paddingTop: 54 }}>
          <div className="success-mark pop">
            <svg width="54" height="54" viewBox="0 0 24 24" fill="none" stroke="oklch(0.68 0.13 58)" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"><path d="M20 6L9 17l-5-5" /></svg>
          </div>
          <h1 className="rise" style={{ "--i": 2 }}>{t("thanks.title")}</h1>
          <p className="lead rise" style={{ "--i": 3 }}>{t("thanks.text", { cafe: window.APP_CONFIG.CAFE.name })}</p>
          <div className="meta rise" style={{ "--i": 4 }}>
            {deliveredIn != null && <span className="chip num"><Icon name="clock" size={14} />{t("thanks.time", { t: fmtClock(deliveredIn) })}</span>}
            <span className="chip num">{t("waiting.order", { n: "#" + (state.order?.number ?? "") })}</span>
          </div>

          <div className="card rate rise" style={{ "--i": 5 }}>
            {sent ? (
              <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 10, fontWeight: 800, padding: "6px 0", animation: "rise .5s var(--ease-out)" }}>
                <span style={{ color: "var(--caramel)", display: "flex" }}>{[...Array(stars)].map((_, i) => <Icon key={i} name="star" size={18} fill="currentColor" stroke={0} />)}</span>
                {t("thanks.sent")}
              </div>
            ) : (
              <>
                <h4>{t("thanks.rate")}</h4>
                <div className="stars" role="radiogroup">
                  {[1, 2, 3, 4, 5].map((n) => (
                    <button key={n} className={`star ${n <= stars ? "on" : ""}`} role="radio" aria-checked={n === stars} aria-label={`${n}/5`} onClick={() => setStars(n)}>
                      <Icon name="star" size={34} fill="currentColor" stroke={0} />
                    </button>
                  ))}
                </div>
                {stars > 0 && (
                  <div className="tags" style={{ animation: "rise .4s var(--ease-out)" }}>
                    {["fast", "tasty", "robot", "friendly"].map((k) => (
                      <button key={k} className="tag" aria-pressed={tags.includes(k)} onClick={() => toggleTag(k)}>{t("thanks.tag." + k)}</button>
                    ))}
                  </div>
                )}
                {stars > 0 && <div style={{ marginTop: 16 }}><Button variant="accent" loading={sending} onClick={send}>{t("thanks.send")}</Button></div>}
              </>
            )}
          </div>
          <div style={{ height: 20 }} />
        </div>
      </div>
      <div className="footer-bar" style={{ width: "100%" }}>
        <Button variant="outline" onClick={() => dispatch({ type: "NEW_ORDER" })}><Icon name="plus" size={18} />{t("thanks.new")}</Button>
      </div>
    </div>
  );
}
window.ThanksScreen = ThanksScreen;
