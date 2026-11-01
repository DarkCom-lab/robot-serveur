/* =====================================================================
 * Écran 3 — Confirmation : récapitulatif modifiable + numéro de table
 * ===================================================================== */
function ReviewLine({ line }) {
  const { dispatch, t, loc, fmtPrice } = useStore();
  const [removing, setRemoving] = useState(false);
  const name = loc(line.item.name);
  const remove = () => { setRemoving(true); setTimeout(() => dispatch({ type: "CART_REMOVE", id: line.item.id }), 320); };
  const dec = () => (line.qty === 1 ? remove() : dispatch({ type: "CART_DEC", id: line.item.id }));

  return (
    <div className={`line ${removing ? "removing" : ""}`}>
      <div className="line-thumb"><ProductImage src={line.item.image} alt={name} /></div>
      <div style={{ minWidth: 0 }}>
        <h4>{name}</h4>
        <div className="each num">{t("review.each", { price: fmtPrice(line.item.price) })}</div>
        <div className="row2">
          <QtyStepper qty={line.qty} onInc={() => dispatch({ type: "CART_ADD", id: line.item.id })} onDec={dec}
            labelInc={t("menu.add", { name })} labelDec={t("menu.removeOne", { name })} />
          <button className="del" onClick={remove}><Icon name="trash" size={15} />{t("review.remove")}</button>
        </div>
      </div>
      <div className="lt num">{fmtPrice(line.total)}</div>
    </div>
  );
}

function ReviewScreen() {
  const { state, dispatch, t, fmtPrice, cartLines, cartCount, cartTotal, menu, loadMenu } = useStore();
  useEffect(() => { if (menu.status !== "ready") loadMenu(); }, []);
  const toMenu = () => dispatch({ type: "GO", screen: "menu" });

  return (
    <div className="screen">
      <TopBar onBack={toMenu} title={t("review.title")} right={cartCount ? <span className="chip num">{t("cart.count", { n: cartCount })}</span> : null} />

      {cartLines.length === 0 ? (
        <div className="empty">
          <div className="cup"><Icon name="cup" size={52} stroke={1.4} /></div>
          <h3>{t("review.empty")}</h3>
          <p>{t("review.emptyText")}</p>
          <div style={{ width: 240 }}><Button variant="primary" onClick={toMenu}>{t("review.backToMenu")}</Button></div>
        </div>
      ) : (
        <>
          <div className="scroll">
            <div className="table-card rise">
              <div className="tnum num">{state.table}</div>
              <div><small>{t("review.deliverTo")}</small><strong>{t("common.table", { n: state.table })}</strong></div>
            </div>
            <div className="card line-items rise" style={{ "--i": 1 }}>
              {cartLines.map((l) => <ReviewLine key={l.item.id} line={l} />)}
            </div>
            <button className="add-more rise" style={{ "--i": 2 }} onClick={toMenu}><Icon name="plus" size={18} />{t("review.addMore")}</button>
            <div className="card totals rise" style={{ "--i": 3 }}>
              <div className="r"><span>{t("review.subtotal")}</span><span className="num">{fmtPrice(cartTotal)}</span></div>
              <div className="r big"><span>{t("review.total")}</span><span className="num">{fmtPrice(cartTotal)}</span></div>
            </div>
            <div style={{ height: 12 }} />
          </div>
          <div className="footer-bar">
            <Button variant="primary" onClick={() => dispatch({ type: "GO", screen: "payment" })}>
              {t("review.confirm")} · <span className="num">{fmtPrice(cartTotal)}</span>
            </Button>
          </div>
        </>
      )}
    </div>
  );
}
window.ReviewScreen = ReviewScreen;
