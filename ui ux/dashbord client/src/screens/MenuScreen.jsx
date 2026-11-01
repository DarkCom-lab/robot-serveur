/* =====================================================================
 * Écran 2 — Menu : catégories (scrollspy), cartes produit, panier flottant
 * ===================================================================== */

/** Animation "pastille qui vole vers le panier". */
function flyToCart(fromEl) {
  const target = document.querySelector(".cart-bag");
  if (!fromEl || !target || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  const a = fromEl.getBoundingClientRect(), b = target.getBoundingClientRect();
  const dot = document.createElement("div");
  dot.className = "fly-dot";
  dot.style.left = a.left + a.width / 2 - 9 + "px";
  dot.style.top = a.top + a.height / 2 - 9 + "px";
  document.body.appendChild(dot);
  const dx = b.left + b.width / 2 - (a.left + a.width / 2);
  const dy = b.top + b.height / 2 - (a.top + a.height / 2);
  dot.animate(
    [
      { transform: "translate(0,0) scale(1)", opacity: 1 },
      { transform: `translate(${dx * .5}px, ${dy * .5 - 80}px) scale(1.15)`, opacity: 1, offset: .5 },
      { transform: `translate(${dx}px, ${dy}px) scale(.4)`, opacity: .6 }
    ],
    { duration: 620, easing: "cubic-bezier(.5,0,.6,1)" }
  ).onfinish = () => dot.remove();
}

function ProductCard({ item, index }) {
  const { state, dispatch, t, loc, fmtPrice } = useStore();
  const qty = state.cart[item.id] || 0;
  const name = loc(item.name);
  const add = (e) => { dispatch({ type: "CART_ADD", id: item.id }); flyToCart(e.currentTarget); };

  return (
    <article className={`product rise ${qty ? "in-cart" : ""} ${item.soldOut ? "sold-out" : ""}`} style={{ "--i": index }}>
      <div className="product-img">
        <ProductImage src={item.image} alt={name} />
        {item.soldOut && <span className="badge out">{t("menu.soldOut")}</span>}
      </div>
      <div className="product-body">
        <h4>{name}</h4>
        {item.tags?.includes("signature") && <span style={{ marginTop: 4 }}><span className="badge"><Icon name="sparkle" size={10} stroke={2.4} />{t("menu.signature")}</span></span>}
        <p>{loc(item.description)}</p>
        <div className="product-foot">
          <span className="price num">{fmtPrice(item.price)}</span>
          {qty > 0 ? (
            <QtyStepper qty={qty}
              onInc={(e) => add(e)}
              onDec={() => dispatch({ type: "CART_DEC", id: item.id })}
              labelInc={t("menu.add", { name })} labelDec={t("menu.removeOne", { name })} />
          ) : (
            <button className="add-btn" disabled={item.soldOut} onClick={add} aria-label={t("menu.add", { name })}>
              <Icon name="plus" size={20} stroke={2.4} />
            </button>
          )}
        </div>
      </div>
    </article>
  );
}

function MenuSkeleton() {
  return (
    <div className="product-list" aria-busy="true">
      {[0, 1, 2, 3].map((i) => (
        <div key={i} className="product" style={{ boxShadow: "none" }}>
          <div className="skel" style={{ width: 104, height: 112, borderRadius: 18 }} />
          <div style={{ display: "flex", flexDirection: "column", gap: 8, paddingTop: 6 }}>
            <div className="skel" style={{ height: 16, width: "60%" }} />
            <div className="skel" style={{ height: 11, width: "92%" }} />
            <div className="skel" style={{ height: 11, width: "70%" }} />
            <div style={{ marginTop: "auto", display: "flex", justifyContent: "space-between" }}>
              <div className="skel" style={{ height: 18, width: 60 }} />
              <div className="skel" style={{ height: 44, width: 44, borderRadius: 22 }} />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

function MenuError() {
  const { t, loadMenu } = useStore();
  return (
    <div className="empty">
      <div className="cup" style={{ color: "var(--danger)" }}><Icon name="alert" size={44} stroke={1.5} /></div>
      <h3>{t("menu.errorTitle")}</h3>
      <p>{t("menu.errorText")}</p>
      <div style={{ width: 220 }}><Button variant="primary" onClick={loadMenu}><Icon name="refresh" size={18} />{t("menu.retry")}</Button></div>
    </div>
  );
}

function CartBar() {
  const { dispatch, t, fmtPrice, cartCount, cartTotal } = useStore();
  const [bump, setBump] = useState(false);
  const prev = useRef(cartCount);
  useEffect(() => {
    if (cartCount > prev.current) { setBump(false); requestAnimationFrame(() => setBump(true)); }
    prev.current = cartCount;
  }, [cartCount]);

  return (
    <button className={`cart-bar ${cartCount ? "show" : ""} ${bump ? "bump" : ""}`} onAnimationEnd={() => setBump(false)}
      onClick={() => dispatch({ type: "GO", screen: "review" })} aria-hidden={!cartCount} tabIndex={cartCount ? 0 : -1}>
      <span className="cart-bag"><Icon name="bag" size={22} /><span className="n num">{cartCount}</span></span>
      <span className="cart-info" style={{ textAlign: "start" }}>
        <small>{t("cart.count", { n: cartCount })}</small>
        <strong className="num">{fmtPrice(cartTotal)}</strong>
      </span>
      <span className="cart-go">{t("cart.view")} <Icon name="chevron" size={16} stroke={2.6} className="flip-rtl" /></span>
    </button>
  );
}

function MenuScreen() {
  const { state, dispatch, menu, loadMenu, t, loc } = useStore();
  const [activeCat, setActiveCat] = useState(null);
  const scrollRef = useRef(null);
  const sectionRefs = useRef({});
  const catsRef = useRef(null);

  useEffect(() => { if (menu.status === "idle" || menu.status === "error") loadMenu(); }, []);
  useEffect(() => { if (menu.data && !activeCat) setActiveCat(menu.data.categories[0].id); }, [menu.data]);

  // Scrollspy : la catégorie visible devient active
  const onScroll = () => {
    const sc = scrollRef.current; if (!sc || !menu.data) return;
    const top = sc.scrollTop + 90;
    let cur = menu.data.categories[0].id;
    menu.data.categories.forEach((c) => { const el = sectionRefs.current[c.id]; if (el && el.offsetTop <= top) cur = c.id; });
    if (cur !== activeCat) setActiveCat(cur);
  };
  // Garde l'onglet actif visible dans la barre horizontale
  useEffect(() => {
    const el = catsRef.current?.querySelector(`[data-cat="${activeCat}"]`);
    if (el && catsRef.current) {
      const c = catsRef.current;
      c.scrollTo({ left: el.offsetLeft - c.offsetWidth / 2 + el.offsetWidth / 2, behavior: "smooth" });
    }
  }, [activeCat]);

  const jump = (id) => {
    setActiveCat(id);
    const el = sectionRefs.current[id];
    if (el) scrollRef.current.scrollTo({ top: el.offsetTop - 64, behavior: "smooth" });
  };

  const countByCat = (cid) => Object.entries(state.cart).reduce((s, [id, q]) => {
    const it = menu.data?.items.find((i) => i.id === id); return s + (it?.categoryId === cid ? q : 0);
  }, 0);

  return (
    <div className="screen">
      <TopBar onBack={() => dispatch({ type: "GO", screen: "welcome" })} title="" right={<TableChip />} />
      <div className="scroll" ref={scrollRef} onScroll={onScroll}>
        <div className="menu-head rise">
          <h1>{t("menu.title")}</h1>
          <p>{t("menu.subtitle")}</p>
        </div>

        {menu.status === "error" && <MenuError />}
        {(menu.status === "loading" || menu.status === "idle") && (
          <>
            <div className="cats">{[90, 120, 100].map((w, i) => <div key={i} className="skel" style={{ width: w, height: 44, borderRadius: 22, flex: "none" }} />)}</div>
            <MenuSkeleton />
          </>
        )}

        {menu.status === "ready" && (
          <>
            <div className="cats" ref={catsRef} role="tablist">
              {menu.data.categories.map((c) => {
                const n = countByCat(c.id);
                return (
                  <button key={c.id} data-cat={c.id} className="cat" role="tab" aria-selected={activeCat === c.id} onClick={() => jump(c.id)}>
                    {loc(c.label)}{n > 0 && <span className="count num">{n}</span>}
                  </button>
                );
              })}
            </div>
            {menu.data.categories.map((c) => {
              const items = menu.data.items.filter((i) => i.categoryId === c.id);
              return (
                <section key={c.id} ref={(el) => (sectionRefs.current[c.id] = el)}>
                  <div className="section-title"><h3>{loc(c.label)}</h3><span className="num">{items.length}</span></div>
                  <div className="product-list">
                    {items.map((it, i) => <ProductCard key={it.id} item={it} index={i} />)}
                  </div>
                </section>
              );
            })}
            <div style={{ height: 110 }} />
          </>
        )}
      </div>
      <CartBar />
    </div>
  );
}
window.MenuScreen = MenuScreen;
