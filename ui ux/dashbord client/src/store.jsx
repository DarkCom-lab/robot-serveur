/* =====================================================================
 * store.jsx — État centralisé (useReducer + Context)
 * ---------------------------------------------------------------------
 * Une seule source de vérité : écran, table, panier, commande, statut,
 * paiement, étage/zone, chrono. Persistée en localStorage pour qu'un
 * rafraîchissement ne fasse pas perdre la commande en cours.
 * ===================================================================== */
const { createContext, useContext, useReducer, useEffect, useMemo, useCallback, useRef, useState } = React;

const STORAGE_KEY = "cafe.state.v1";

/** Ordre des écrans (sert à choisir le sens de la transition). */
const SCREEN_ORDER = ["welcome", "menu", "review", "payment", "waiting", "robot", "reception", "thanks"];

/** Lecture de ?table=12 dans l'URL (simulation du scan QR). */
function readTableFromURL() {
  const p = new URLSearchParams(window.location.search);
  const t = parseInt(p.get("table"), 10);
  return Number.isFinite(t) && t > 0 ? t : null;
}

const initialState = {
  screen: "welcome",
  direction: 1,                 // 1 = avance, -1 = retour (animation)
  lang: window.APP_CONFIG.DEFAULT_LANG,
  table: null,
  tableFromQR: false,
  cart: {},                     // { [itemId]: qty }
  paymentMethod: null,          // "card" | "cash"
  order: null,                  // { id, number, total, createdAt, items }
  status: null,                 // processing | robot_picked | delivering | delivered | completed
  step: null,                   // received | preparing (détail de processing)
  robotProgress: 0,             // 0..1
  location: null,               // { floor, zone }
  timestamps: {},               // { received, preparing, robot_picked, delivering, delivered, completed }
  calledToPay: false,
  rating: null
};

function loadState() {
  const urlTable = readTableFromURL();
  let saved = null;
  try { saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || "null"); } catch (e) {}
  const base = { ...initialState, ...(saved || {}) };
  // Un nouveau scan (table différente) sans commande active => repart à zéro
  if (urlTable && urlTable !== base.table && !base.order) {
    return { ...initialState, lang: base.lang, table: urlTable, tableFromQR: true };
  }
  if (urlTable) { base.table = urlTable; base.tableFromQR = true; }
  if (!base.table) { base.table = window.APP_CONFIG.DEFAULT_TABLE; base.tableFromQR = false; }
  return base;
}

function reducer(state, action) {
  switch (action.type) {
    case "GO": {
      const dir = SCREEN_ORDER.indexOf(action.screen) >= SCREEN_ORDER.indexOf(state.screen) ? 1 : -1;
      return { ...state, screen: action.screen, direction: action.direction ?? dir };
    }
    case "SET_LANG": return { ...state, lang: action.lang };
    case "SET_TABLE": return { ...state, table: action.table, tableFromQR: true };

    case "CART_ADD": {
      const q = (state.cart[action.id] || 0) + 1;
      return { ...state, cart: { ...state.cart, [action.id]: Math.min(q, 20) } };
    }
    case "CART_DEC": {
      const q = (state.cart[action.id] || 0) - 1;
      const cart = { ...state.cart };
      if (q <= 0) delete cart[action.id]; else cart[action.id] = q;
      return { ...state, cart };
    }
    case "CART_REMOVE": {
      const cart = { ...state.cart }; delete cart[action.id];
      return { ...state, cart };
    }

    case "SET_PAYMENT": return { ...state, paymentMethod: action.method };

    case "ORDER_CREATED":
      return {
        ...state, order: action.order, status: "processing", step: "received",
        timestamps: { received: action.order.createdAt }, robotProgress: 0, location: null,
        calledToPay: false, rating: null, screen: "waiting", direction: 1
      };

    case "STATUS_UPDATE": {
      const { status, step, robotProgress } = action.payload;
      const ts = { ...state.timestamps };
      const now = Date.now();
      if (step === "preparing" && !ts.preparing) ts.preparing = now;
      ["robot_picked", "delivering", "delivered", "completed"].forEach((s) => {
        if (status === s && !ts[s]) ts[s] = now;
      });
      // Statuts ultérieurs => les précédents sont forcément atteints
      if (["robot_picked", "delivering", "delivered"].includes(status) && !ts.preparing) ts.preparing = now;
      return { ...state, status, step: step ?? state.step, robotProgress: robotProgress ?? state.robotProgress, timestamps: ts };
    }

    case "SET_LOCATION": return { ...state, location: action.location };
    case "CALLED_TO_PAY": return { ...state, calledToPay: true };
    case "RECEIVED":
      return { ...state, status: "completed", timestamps: { ...state.timestamps, completed: Date.now() }, screen: "thanks", direction: 1 };
    case "SET_RATING": return { ...state, rating: action.rating };

    case "NEW_ORDER":
      return { ...initialState, lang: state.lang, table: state.table, tableFromQR: state.tableFromQR, screen: "menu", direction: 1 };
    case "RESET":
      return { ...initialState, lang: state.lang, table: state.table, tableFromQR: state.tableFromQR };
    default: return state;
  }
}

const StoreCtx = createContext(null);

function StoreProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, undefined, loadState);
  const [menu, setMenu] = useState({ status: "idle", data: null, error: null });

  // Persistance
  useEffect(() => {
    const { direction, ...persist } = state;
    localStorage.setItem(STORAGE_KEY, JSON.stringify(persist));
  }, [state]);

  // Langue + direction du document (prêt pour l'arabe)
  useEffect(() => {
    document.documentElement.lang = state.lang;
    document.documentElement.dir = window.I18N.isRTL(state.lang) ? "rtl" : "ltr";
  }, [state.lang]);

  /* ----- Menu ----- */
  const loadMenu = useCallback(async () => {
    setMenu((m) => ({ ...m, status: "loading", error: null }));
    try {
      const data = await window.CafeAPI.getMenu();
      setMenu({ status: "ready", data, error: null });
    } catch (e) {
      setMenu({ status: "error", data: null, error: e });
    }
  }, []);

  /* ----- Helpers i18n / formatage ----- */
  const t = useCallback((key, vars) => window.I18N.translate(state.lang, key, vars), [state.lang]);
  const loc = useCallback((field) => (field && typeof field === "object" ? field[state.lang] ?? field.fr : field), [state.lang]);
  const fmtPrice = useCallback((v) => {
    const n = new Intl.NumberFormat(state.lang === "ar" ? "ar-MA" : window.APP_CONFIG.CURRENCY.locale, { maximumFractionDigits: 2 }).format(v);
    return `${n} ${window.APP_CONFIG.CURRENCY.symbol}`;
  }, [state.lang]);

  /* ----- Dérivés du panier ----- */
  const itemsById = useMemo(() => {
    const map = {};
    (menu.data?.items || []).forEach((it) => (map[it.id] = it));
    return map;
  }, [menu.data]);

  const cartLines = useMemo(() =>
    Object.entries(state.cart)
      .filter(([id]) => itemsById[id])
      .map(([id, qty]) => ({ item: itemsById[id], qty, total: itemsById[id].price * qty })),
  [state.cart, itemsById]);

  const cartCount = cartLines.reduce((s, l) => s + l.qty, 0);
  const cartTotal = cartLines.reduce((s, l) => s + l.total, 0);

  const value = { state, dispatch, menu, loadMenu, t, loc, fmtPrice, itemsById, cartLines, cartCount, cartTotal };
  return <StoreCtx.Provider value={value}>{children}</StoreCtx.Provider>;
}

const useStore = () => useContext(StoreCtx);

/* =====================================================================
 * useOrderTracking — polling du statut + routage automatique des écrans
 * ===================================================================== */
function useOrderTracking() {
  const { state, dispatch } = useStore();
  const [netError, setNetError] = useState(false);
  const orderId = state.order?.id;
  const active = orderId && ["waiting", "robot", "reception"].includes(state.screen);

  useEffect(() => {
    if (!active) return;
    let alive = true, timer;
    const tick = async () => {
      try {
        const s = await window.CafeAPI.getOrderStatus(orderId);
        if (!alive) return;
        setNetError(false);
        dispatch({ type: "STATUS_UPDATE", payload: s });
      } catch (e) {
        if (alive) setNetError(true);
      }
      if (alive) timer = setTimeout(tick, window.APP_CONFIG.POLL_INTERVAL_MS);
    };
    tick();
    return () => { alive = false; clearTimeout(timer); };
  }, [active, orderId]);

  // Récupère étage + zone dès que le robot a la commande
  useEffect(() => {
    if (!orderId || state.location) return;
    if (["robot_picked", "delivering", "delivered"].includes(state.status)) {
      window.CafeAPI.getOrderLocation(orderId)
        .then((location) => dispatch({ type: "SET_LOCATION", location }))
        .catch(() => setNetError(true));
    }
  }, [state.status, orderId, state.location]);

  // Statut => écran
  useEffect(() => {
    if (!active) return;
    const target =
      state.status === "processing" ? "waiting" :
      state.status === "robot_picked" || state.status === "delivering" ? "robot" :
      state.status === "delivered" ? "reception" : null;
    if (target && target !== state.screen) dispatch({ type: "GO", screen: target, direction: 1 });
  }, [state.status, active]);

  return { netError };
}

/** Chronomètre : secondes écoulées depuis `start`, figé à `end` si fourni. */
function useElapsed(start, end) {
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    if (!start || end) return;
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, [start, end]);
  if (!start) return 0;
  return Math.max(0, Math.floor(((end || now) - start) / 1000));
}

const fmtClock = (sec) => `${String(Math.floor(sec / 60)).padStart(2, "0")}:${String(sec % 60).padStart(2, "0")}`;

Object.assign(window, { StoreProvider, useStore, useOrderTracking, useElapsed, fmtClock, SCREEN_ORDER });
