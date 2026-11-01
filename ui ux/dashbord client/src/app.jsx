/* =====================================================================
 * app.jsx — Routeur d'écrans + panneau de démo (hors produit)
 * ===================================================================== */
const SCREENS = {
  welcome: WelcomeScreen,
  menu: MenuScreen,
  review: ReviewScreen,
  payment: PaymentScreen,
  waiting: WaitingScreen,
  robot: RobotScreen,
  reception: ReceptionScreen,
  thanks: ThanksScreen
};

function Router() {
  const { state } = useStore();
  const { netError } = useOrderTracking();
  const Screen = SCREENS[state.screen] || WelcomeScreen;
  return (
    <div className="phone" data-screen-label={state.screen}>
      <NetBanner show={netError} />
      {/* key => remonte l'écran pour jouer la transition d'entrée */}
      <div key={state.screen} className={`screen screen-enter ${state.direction < 0 ? "back" : ""}`}>
        <Screen />
      </div>
    </div>
  );
}

/** Panneau de démo : simule le scan, la langue, accélère les statuts. */
function DevPanel() {
  const { state, dispatch, cartCount } = useStore();
  const [open, setOpen] = useState(false);
  const [table, setTable] = useState(state.table);
  const [failArmed, setFailArmed] = useState(false);

  const scan = () => {
    const n = parseInt(table, 10); if (!n) return;
    const url = new URL(window.location.href); url.searchParams.set("table", n);
    window.history.replaceState(null, "", url);
    dispatch({ type: "SET_TABLE", table: n });
  };
  const armFail = () => { window.APP_CONFIG.MOCK.FAIL_NEXT = true; setFailArmed(true); setTimeout(() => setFailArmed(false), 4000); };

  return (
    <>
      <button className="dev-toggle" onClick={() => setOpen((o) => !o)}>DÉMO</button>
      <aside className={`devpanel ${open ? "open" : ""}`}>
        <h5>Panneau démo</h5>
        <div className="desc">Outils de test — ne fait pas partie de l'app client. API&nbsp;: <code>{window.APP_CONFIG.API_BASE_URL}</code></div>

        <div className="grp">
          <label>Scan QR · ?table=</label>
          <div className="row">
            <input type="number" min="1" value={table} onChange={(e) => setTable(e.target.value)} aria-label="Numéro de table" />
            <button onClick={scan}>Scanner</button>
          </div>
        </div>

        <div className="grp">
          <label>Langue</label>
          <div className="row">
            {window.I18N.languages.map((l) => (
              <button key={l} className={state.lang === l ? "on" : ""} onClick={() => dispatch({ type: "SET_LANG", lang: l })}>{l === "fr" ? "Français" : "العربية"}</button>
            ))}
          </div>
        </div>

        <div className="grp">
          <label>Commande</label>
          <div className="row">
            <button disabled={!state.order} onClick={() => window.MockServer.skip(state.order?.id)}>Statut suivant →</button>
            <button className={failArmed ? "on" : ""} onClick={armFail}>Simuler erreur</button>
            <button onClick={() => { window.MockServer.reset(); dispatch({ type: "RESET" }); }}>Réinitialiser</button>
          </div>
        </div>

        <div className="grp">
          <label>État</label>
          <div className="state">{
`screen        ${state.screen}
table         ${state.table}
cart          ${cartCount} article(s)
paymentMethod ${state.paymentMethod ?? "—"}
status        ${state.status ?? "—"}${state.step && state.status === "processing" ? " / " + state.step : ""}
location      ${state.location ? `étage ${state.location.floor}, zone ${state.location.zone}` : "—"}
robot         ${Math.round((state.robotProgress || 0) * 100)} %`}</div>
        </div>
      </aside>
    </>
  );
}

function App() {
  return (
    <StoreProvider>
      <div className="stage">
        <Router />
        <DevPanel />
      </div>
    </StoreProvider>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
