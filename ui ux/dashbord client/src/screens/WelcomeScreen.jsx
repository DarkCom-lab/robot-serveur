/* =====================================================================
 * Écran 1 — Accueil (après scan du QR code /?table=12)
 * ===================================================================== */
function WelcomeScreen() {
  const { state, dispatch, t, loadMenu, menu } = useStore();
  const cafe = window.APP_CONFIG.CAFE;

  // Précharge le menu pendant que le client lit l'accueil
  useEffect(() => { if (menu.status === "idle") loadMenu(); }, []);

  return (
    <div className="screen welcome">
      <div className="welcome-hero"><img src="assets/hero.jpg" alt="" /></div>
      <div className="steam" aria-hidden="true"><span /><span /><span /></div>

      <div className="table-tag pop" style={{ "--d": "500ms" }}>
        <span className="qr"><Icon name="qr" size={16} stroke={2} /></span>
        <span>
          {state.tableFromQR && <small>{t("welcome.scanned")}</small>}
          {t("common.table", { n: state.table })}
        </span>
      </div>

      <div className="welcome-content">
        <div className="brand-mark pop" style={{ "--d": "100ms" }}>{cafe.name[0]}</div>
        <div className="greet rise" style={{ "--i": 1 }}>{t("welcome.greeting")}</div>
        <h1 className="rise" style={{ "--i": 2 }}>{cafe.name}</h1>
        <div className="tagline rise" style={{ "--i": 3 }}>{cafe.tagline}</div>
        <p className="sub rise" style={{ "--i": 4 }}>{t("welcome.subtitle")}</p>

        {!state.tableFromQR && (
          <div className="warn rise" style={{ "--i": 5 }}>
            <Icon name="alert" size={18} /> <span>{t("welcome.noTable")}</span>
          </div>
        )}

        <div className="rise" style={{ "--i": 5 }}>
          <Button variant="accent" onClick={() => dispatch({ type: "GO", screen: "menu" })}>
            {t("welcome.cta")} <Icon name="chevron" size={20} stroke={2.4} className="flip-rtl" />
          </Button>
        </div>
        <div className="hint rise" style={{ "--i": 6 }}>
          <Icon name="card" size={15} /> <Icon name="cash" size={15} /> {t("welcome.hint")}
        </div>
      </div>
    </div>
  );
}
window.WelcomeScreen = WelcomeScreen;
