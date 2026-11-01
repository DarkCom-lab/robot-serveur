/* =====================================================================
 * api.js — Couche d'accès aux données (unique point de contact backend)
 * ---------------------------------------------------------------------
 * Toutes les fonctions renvoient des Promises. Les composants n'appellent
 * JAMAIS fetch directement : ils passent par window.CafeAPI.
 *
 * Si APP_CONFIG.API_BASE_URL === "mock"  → réponses simulées (MockServer)
 * Sinon                                   → requêtes HTTP réelles (fetch)
 *
 * ENDPOINTS ATTENDUS CÔTÉ SERVEUR
 * ---------------------------------------------------------------------
 *  GET  /api/menu
 *       → { categories: [{ id, label }], items: [{ id, categoryId, name,
 *            description, price, image, tags?, soldOut? }] }
 *
 *  POST /api/orders
 *       body  { table, items: [{ id, qty }], paymentMethod: "card"|"cash", lang }
 *       → { id, number, total, createdAt, status: "processing" }
 *
 *  GET  /api/orders/:id/status
 *       → { status: "processing"|"robot_picked"|"delivering"|"delivered"|"completed",
 *           step?: "received"|"preparing",   // détail facultatif pendant processing
 *           robotProgress?: 0..1,            // avancement du robot (facultatif)
 *           updatedAt }
 *
 *  GET  /api/orders/:id/location
 *       → { floor: number, zone: "A"|"B" }
 *
 *  POST /api/orders/:id/received
 *       → { ok: true, status: "completed" }
 *
 *  POST /api/orders/:id/call-to-pay
 *       → { ok: true }
 *
 *  (bonus, facultatif) POST /api/orders/:id/rating  body { stars, tags }
 * ===================================================================== */
(function () {
  const CFG = window.APP_CONFIG;
  const isMock = () => CFG.API_BASE_URL === "mock";

  /* ------------------------------------------------------------------
   * Transport HTTP réel
   * ------------------------------------------------------------------ */
  async function http(method, path, body) {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), CFG.REQUEST_TIMEOUT_MS);
    try {
      const res = await fetch(CFG.API_BASE_URL.replace(/\/$/, "") + path, {
        method,
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: body ? JSON.stringify(body) : undefined,
        signal: ctrl.signal
      });
      if (!res.ok) throw new ApiError(`HTTP ${res.status}`, res.status);
      return res.status === 204 ? { ok: true } : await res.json();
    } catch (e) {
      if (e instanceof ApiError) throw e;
      throw new ApiError(e.name === "AbortError" ? "timeout" : "network", 0);
    } finally {
      clearTimeout(timer);
    }
  }

  class ApiError extends Error {
    constructor(message, status) { super(message); this.status = status; }
  }

  /* ------------------------------------------------------------------
   * Serveur simulé (mock) — même contrat que le vrai backend
   * ------------------------------------------------------------------ */
  const MENU = {
    categories: [
      { id: "hot", label: { fr: "Boissons chaudes", ar: "مشروبات ساخنة" } },
      { id: "cold", label: { fr: "Boissons froides", ar: "مشروبات باردة" } },
      { id: "pastry", label: { fr: "Pâtisseries", ar: "معجنات" } }
    ],
    items: [
      { id: "espresso", categoryId: "hot", price: 15, image: "assets/espresso.jpg", tags: ["signature"],
        name: { fr: "Espresso", ar: "إسبريسو" },
        description: { fr: "Mélange maison, notes de cacao et de noisette grillée.", ar: "خلطة البيت بنكهة الكاكاو والبندق." } },
      { id: "cappuccino", categoryId: "hot", price: 22, image: "assets/cappuccino.jpg",
        name: { fr: "Cappuccino", ar: "كابتشينو" },
        description: { fr: "Double espresso, lait micro-moussé, latte art.", ar: "إسبريسو مزدوج مع حليب مرغّى." } },
      { id: "americano", categoryId: "hot", price: 18, image: "assets/americano.jpg",
        name: { fr: "Americano", ar: "أمريكانو" },
        description: { fr: "Espresso allongé à l'eau chaude, doux et rond.", ar: "إسبريسو ممدود بالماء الساخن." } },
      { id: "mint-tea", categoryId: "hot", price: 16, image: "assets/the-menthe.jpg", tags: ["signature"],
        name: { fr: "Thé à la menthe", ar: "أتاي بالنعناع" },
        description: { fr: "Gunpowder infusé, menthe fraîche du jour.", ar: "شاي أخضر بالنعناع الطازج." } },
      { id: "hot-chocolate", categoryId: "hot", price: 24, image: null, soldOut: true,
        name: { fr: "Chocolat chaud", ar: "شوكولاتة ساخنة" },
        description: { fr: "Chocolat noir 70 %, lait entier, chantilly.", ar: "شوكولاتة داكنة 70٪ مع الحليب." } },

      { id: "orange", categoryId: "cold", price: 20, image: "assets/jus-orange.jpg",
        name: { fr: "Jus d'orange pressé", ar: "عصير برتقال طازج" },
        description: { fr: "Oranges pressées à la commande, sans sucre ajouté.", ar: "برتقال معصور عند الطلب." } },
      { id: "citrus", categoryId: "cold", price: 26, image: "assets/jus-presse.jpg",
        name: { fr: "Agrumes & gingembre", ar: "حمضيات وزنجبيل" },
        description: { fr: "Orange, pamplemousse, citron vert, pointe de gingembre.", ar: "برتقال، جريب فروت، ليمون وزنجبيل." } },
      { id: "fruit-cocktail", categoryId: "cold", price: 28, image: "assets/cocktail.jpg", tags: ["signature"],
        name: { fr: "Cocktail Ambre", ar: "كوكتيل عنبر" },
        description: { fr: "Mangue, orange et passion, servi bien frais.", ar: "مانجو، برتقال وفاكهة العاطفة." } },
      { id: "iced-latte", categoryId: "cold", price: 25, image: null,
        name: { fr: "Iced latte", ar: "لاتيه مثلج" },
        description: { fr: "Espresso, lait froid, glaçons, sirop vanille au choix.", ar: "إسبريسو، حليب بارد وثلج." } },

      { id: "croissant", categoryId: "pastry", price: 12, image: "assets/croissant.jpg",
        name: { fr: "Croissant pur beurre", ar: "كرواسون بالزبدة" },
        description: { fr: "Feuilletage maison, beurre AOP, cuit ce matin.", ar: "عجين مورق محضّر في البيت." } },
      { id: "pain-choc", categoryId: "pastry", price: 14, image: "assets/pain-chocolat.jpg",
        name: { fr: "Pain au chocolat", ar: "خبز بالشوكولاتة" },
        description: { fr: "Deux barres de chocolat noir, croustillant.", ar: "قطعتان من الشوكولاتة الداكنة." } },
      { id: "almond", categoryId: "pastry", price: 18, image: "assets/croissant-amande.jpg", tags: ["signature"],
        name: { fr: "Croissant aux amandes", ar: "كرواسون باللوز" },
        description: { fr: "Crème d'amande, amandes effilées torréfiées.", ar: "كريمة اللوز واللوز المحمص." } },
      { id: "cheesecake", categoryId: "pastry", price: 32, image: null,
        name: { fr: "Cheesecake citron", ar: "تشيز كيك بالليمون" },
        description: { fr: "Base sablée, crème légère, coulis de citron.", ar: "قاعدة مقرمشة وكريمة خفيفة بالليمون." } }
    ]
  };

  const MockServer = (function () {
    const KEY = "cafe.mock.orders";
    const orders = JSON.parse(localStorage.getItem(KEY) || "{}");
    const save = () => localStorage.setItem(KEY, JSON.stringify(orders));
    const T = () => CFG.MOCK.TIMELINE_MS;

    const wait = (ms) => new Promise((r) => setTimeout(r, ms));
    async function latency() {
      await wait(CFG.MOCK.LATENCY_MS * (0.6 + Math.random() * 0.8));
      if (CFG.MOCK.FAIL_NEXT) { CFG.MOCK.FAIL_NEXT = false; throw new ApiError("network", 0); }
    }

    /** Emplacement de livraison selon la table (règle simulée). */
    function locationFor(table) {
      const n = Number(table) || 1;
      return { floor: n > 20 ? 2 : 1, zone: ((n - 1) % 20) < 10 ? "A" : "B" };
    }

    /** Statut calculé à partir du temps écoulé (simulation setTimeout-like). */
    function computeStatus(o) {
      if (o.completed) return { status: "completed", robotProgress: 1 };
      const t = Date.now() - o.createdAt + (o.offset || 0);
      const tl = T();
      if (t < tl.robot_picked) return { status: "processing", step: t < tl.preparing ? "received" : "preparing", robotProgress: 0 };
      if (t < tl.delivering) return { status: "robot_picked", robotProgress: 0 };
      if (t < tl.delivered) return { status: "delivering", robotProgress: (t - tl.delivering) / (tl.delivered - tl.delivering) };
      return { status: "delivered", robotProgress: 1 };
    }

    return {
      async getMenu() { await latency(); return JSON.parse(JSON.stringify(MENU)); },

      async createOrder({ table, items, paymentMethod }) {
        await latency();
        if (!items || !items.length) throw new ApiError("empty_cart", 400);
        const id = "ord_" + Math.random().toString(36).slice(2, 9);
        const total = items.reduce((s, it) => s + (MENU.items.find((m) => m.id === it.id)?.price || 0) * it.qty, 0);
        const number = 100 + Math.floor(Math.random() * 899);
        orders[id] = { id, number, table, items, paymentMethod, total, createdAt: Date.now(), offset: 0 };
        save();
        return { id, number, total, createdAt: orders[id].createdAt, status: "processing" };
      },

      async getStatus(id) {
        await wait(120);
        const o = orders[id];
        if (!o) throw new ApiError("not_found", 404);
        return { ...computeStatus(o), updatedAt: Date.now() };
      },

      async getLocation(id) {
        await latency();
        const o = orders[id];
        if (!o) throw new ApiError("not_found", 404);
        return locationFor(o.table);
      },

      async markReceived(id) {
        await latency();
        if (orders[id]) { orders[id].completed = true; save(); }
        return { ok: true, status: "completed" };
      },

      async callToPay(id) { await latency(); await wait(500); return { ok: true }; },
      async rate(id, payload) { await latency(); return { ok: true }; },

      /* --- Outils de démo (non exposés par le vrai backend) --- */
      /** Fait avancer la commande jusqu'au prochain statut. */
      skip(id) {
        const o = orders[id]; if (!o) return;
        const t = Date.now() - o.createdAt + o.offset;
        const marks = Object.values(T()).sort((a, b) => a - b);
        const next = marks.find((m) => m > t + 50);
        if (next != null) { o.offset += next - t; save(); }
      },
      reset() { Object.keys(orders).forEach((k) => delete orders[k]); save(); }
    };
  })();

  /* ------------------------------------------------------------------
   * API publique — c'est ce que l'application consomme
   * ------------------------------------------------------------------ */
  const CafeAPI = {
    /** GET /api/menu */
    getMenu: () => (isMock() ? MockServer.getMenu() : http("GET", "/api/menu")),

    /** POST /api/orders */
    createOrder: (payload) => (isMock() ? MockServer.createOrder(payload) : http("POST", "/api/orders", payload)),

    /** GET /api/orders/:id/status */
    getOrderStatus: (id) => (isMock() ? MockServer.getStatus(id) : http("GET", `/api/orders/${id}/status`)),

    /** GET /api/orders/:id/location */
    getOrderLocation: (id) => (isMock() ? MockServer.getLocation(id) : http("GET", `/api/orders/${id}/location`)),

    /** POST /api/orders/:id/received */
    markReceived: (id) => (isMock() ? MockServer.markReceived(id) : http("POST", `/api/orders/${id}/received`)),

    /** POST /api/orders/:id/call-to-pay */
    callToPay: (id) => (isMock() ? MockServer.callToPay(id) : http("POST", `/api/orders/${id}/call-to-pay`)),

    /** POST /api/orders/:id/rating (facultatif) */
    rateOrder: (id, payload) => (isMock() ? MockServer.rate(id, payload) : http("POST", `/api/orders/${id}/rating`, payload)),

    isMock,
    ApiError
  };

  window.CafeAPI = CafeAPI;
  window.MockServer = MockServer; // outils de démo uniquement
})();
