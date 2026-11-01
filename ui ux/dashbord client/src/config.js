/* =====================================================================
 * config.js — Configuration de l'application
 * ---------------------------------------------------------------------
 * Pour brancher le VRAI serveur : remplacez simplement "mock" par l'URL
 * de votre API (ex : "https://api.cafe-ambre.ma"). Rien d'autre à changer.
 * ===================================================================== */
window.APP_CONFIG = {
  // "mock"  => API simulée en local (voir api.js)
  // "https://..." => appels HTTP réels vers votre backend
  API_BASE_URL: "mock",

  POLL_INTERVAL_MS: 1500,      // fréquence de rafraîchissement du statut
  REQUEST_TIMEOUT_MS: 10000,   // timeout des requêtes HTTP
  DEFAULT_TABLE: 12,           // utilisé si l'URL ne contient pas ?table=
  DEFAULT_LANG: "fr",          // "fr" | "ar"

  CURRENCY: { locale: "fr-FR", symbol: "DH" },
  CAFE: { name: "Ambre", tagline: "Café · Torréfaction · Pâtisserie" },

  // Paramètres du mode mock uniquement
  MOCK: {
    LATENCY_MS: 450,
    // Moment (ms après création) où chaque statut est atteint
    TIMELINE_MS: {
      preparing: 4000,     // processing / step "preparing"
      robot_picked: 11000, // le robot récupère la commande
      delivering: 13500,   // le robot est en route
      delivered: 27000     // le robot est arrivé à la zone
    },
    FAIL_NEXT: false       // true => la prochaine requête échoue (test d'erreur)
  }
};
