/* =====================================================================
 * Écran 4 — Choix du paiement (paymentMethod: "card" | "cash")
 * L'envoi crée la commande (POST /api/orders) et démarre le chrono.
 * ===================================================================== */
function PaymentScreen() {
  const { state, dispatch, t, fmtPrice, cartLines, cartTotal } = useStore();
  const [sending, setSending] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => { if (!cartLines.length) dispatch({ type: "GO", screen: "review" }); }, []);

  const options = [
    { id: "card", icon: "card", title: t("payment.card.title"), desc: t("payment.card.desc") },
    { id: "cash", icon: "cash", title: t("payment.cash.title"), desc: t("payment.cash.desc") }
  ];

  const submit = async () => {
    if (!state.paymentMethod) return;
    setSending(true); setError(null);
    try {
      const res = await window.CafeAPI.createOrder({
        table: state.table,
        items: cartLines.map((l) => ({ id: l.item.id, qty: l.qty })),
        paymentMethod: state.paymentMethod,
        lang: state.lang
      });
      dispatch({
        type: "ORDER_CREATED",
        order: { ...res, items: cartLines.map((l) => ({ id: l.item.id, qty: l.qty, price: l.item.price, name: l.item.name })) }
      });
    } catch (e) {
      setError(t("error.network"));
      setSending(false);
    }
  };

  return (
    <div className="screen">
      <TopBar onBack={() => dispatch({ type: "GO", screen: "review" })} title="" right={<TableChip />} />
      <div className="scroll">
        <div className="pay-head rise">
          <div className="eyebrow">{t("payment.step")}</div>
          <h1>{t("payment.title")}</h1>
          <p>{t("payment.subtitle")}</p>
        </div>
        <div className="pay-options" role="radiogroup" aria-label={t("payment.title")}>
          {options.map((o, i) => (
            <button key={o.id} className="pay-opt rise" style={{ "--i": i + 1 }} role="radio" aria-checked={state.paymentMethod === o.id}
              onClick={() => dispatch({ type: "SET_PAYMENT", method: o.id })}>
              <span className="ic"><Icon name={o.icon} size={26} /></span>
              <span><h4>{o.title}</h4><p>{o.desc}</p></span>
              <span className="radio"><Icon name="check" size={15} stroke={3} /></span>
            </button>
          ))}
        </div>
        <div className="pay-total rise" style={{ "--i": 3 }}>
          <span>{t("payment.toPay")}</span>
          <strong className="num">{fmtPrice(cartTotal)}</strong>
        </div>
      </div>
      <div className="footer-bar">
        {error && <div className="toast-err" role="alert" style={{ margin: "0 0 10px" }}><Icon name="alert" size={18} />{error}</div>}
        <Button variant="primary" loading={sending} disabled={!state.paymentMethod} onClick={submit}>
          {sending ? t("payment.sending") : state.paymentMethod ? t("payment.submit") : t("payment.choose")}
        </Button>
      </div>
    </div>
  );
}
window.PaymentScreen = PaymentScreen;
