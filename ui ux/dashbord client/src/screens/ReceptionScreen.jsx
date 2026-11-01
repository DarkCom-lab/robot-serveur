/* =====================================================================
 * Écran 7a — Réception : "J'ai reçu ma commande" (+ "Call to pay" si TPE)
 * ===================================================================== */
function ReceptionScreen() {
  const { state, dispatch, t, fmtPrice } = useStore();
  const [calling, setCalling] = useState(false);
  const [receiving, setReceiving] = useState(false);
  const [error, setError] = useState(null);
  const loc = state.location;
  const isCard = state.paymentMethod === "card";

  const callToPay = async () => {
    setCalling(true); setError(null);
    try { await window.CafeAPI.callToPay(state.order.id); dispatch({ type: "CALLED_TO_PAY" }); }
    catch (e) { setError(t("error.network")); }
    setCalling(false);
  };

  const received = async () => {
    setReceiving(true); setError(null);
    try { await window.CafeAPI.markReceived(state.order.id); dispatch({ type: "RECEIVED" }); }
    catch (e) { setError(t("error.network")); setReceiving(false); }
  };

  return (
    <div className="screen">
      <TopBar title="" right={<TableChip />} />
      <div className="scroll">
        <div className="reception-head">
          <div className="arrive-badge pop"><Icon name="check" size={32} stroke={2.6} /></div>
          <h1 className="rise" style={{ "--i": 1 }}>{t("reception.title")}</h1>
          <p className="rise" style={{ "--i": 2 }}>{t("reception.text")}</p>
        </div>

        {loc && (
          <div className="loc-banner rise" style={{ "--i": 3 }}>
            <span className="pin"><Icon name="pin" size={24} /></span>
            <div style={{ flex: 1 }}>
              <small>{t("robot.title")}</small>
              <strong>{t("robot.floor")} {loc.floor} · {t("robot.zone")} {loc.zone}</strong>
            </div>
            <div style={{ transform: "scale(.42)", width: 50, height: 54, transformOrigin: "center", display: "grid", placeItems: "center" }}><Robot /></div>
          </div>
        )}

        <div className="rise" style={{ "--i": 4, padding: "0 0" }}><div style={{ padding: "0 4px" }}><OrderSteps /></div></div>
        <div style={{ height: 8 }} />
      </div>

      <div className="footer-bar" style={{ display: "grid", gap: 10 }}>
        {error && <div className="toast-err" role="alert" style={{ margin: 0 }}><Icon name="alert" size={18} />{error}</div>}

        {isCard && (state.calledToPay ? (
          <div className="ctp-done" role="status"><Icon name="bell" size={20} className="ring-bell" />{t("reception.called")}</div>
        ) : (
          <Button variant="accent" className="ctp" loading={calling} onClick={callToPay}>
            {!calling && <span className="ic"><Icon name="terminal" size={20} /></span>}
            <span>{calling ? t("reception.calling") : <>{t("reception.callToPay")}<small>{t("reception.callToPayDesc")}</small></>}</span>
          </Button>
        ))}

        {!isCard && (
          <div className="cash-note"><Icon name="cash" size={20} /><span>{t("reception.cashNote", { total: fmtPrice(state.order?.total || 0) })}</span></div>
        )}

        <Button variant="primary" loading={receiving} onClick={received}>
          {!receiving && <Icon name="check" size={20} stroke={2.6} />}{t("reception.received")}
        </Button>
      </div>
    </div>
  );
}
window.ReceptionScreen = ReceptionScreen;
