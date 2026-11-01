# Ambre — Application de commande à table

Application mobile-first : le client scanne le QR code de sa table, commande, choisit son paiement, suit la préparation puis la livraison par robot.

## Structure

```
index.html                 Point d'entrée (charge tout dans l'ordre)
assets/                    Photos produits + visuel d'accueil
src/
  config.js                ← API_BASE_URL : "mock" ou URL du vrai serveur
  api.js                   Couche API unique (mock + fetch réel), endpoints documentés
  i18n.js                  Traductions FR / AR (+ RTL automatique)
  store.jsx                État centralisé (useReducer) + polling du statut + chrono
  ui.jsx                   Icônes, boutons, stepper, robot, confettis
  styles.css               Système visuel (tokens couleurs, typo, animations)
  app.jsx                  Routeur d'écrans + panneau de démo
  screens/
    WelcomeScreen.jsx      1. Accueil / scan QR
    MenuScreen.jsx         2. Menu + panier flottant
    ReviewScreen.jsx       3. Confirmation (modifier / supprimer)
    PaymentScreen.jsx      4. TPE ou Espèces  → POST /api/orders
    WaitingScreen.jsx      5. Chrono + étapes Reçue → Préparation → Livraison
    RobotScreen.jsx        6. Robot : étage, zone A/B, plan animé
    ReceptionScreen.jsx    7. « J'ai reçu ma commande » (+ « Call to pay » si TPE)
    ThanksScreen.jsx       Remerciement + note
```

## Lancer

Aucune installation. Servez le dossier avec n'importe quel serveur statique :

```
npx serve .         # ou : python3 -m http.server 8080
```

Puis ouvrez `http://localhost:8080/?table=12` (le paramètre `table` simule le scan du QR code).
Le panneau « Démo » (à droite sur desktop, onglet latéral sur mobile) permet de changer de table, de langue, d'avancer au statut suivant, de simuler une erreur réseau et de réinitialiser.

## Brancher le vrai backend

1. Dans `src/config.js`, remplacez `API_BASE_URL: "mock"` par l'URL du serveur, ex. `"https://api.mon-cafe.ma"`.
2. Implémentez côté serveur les endpoints décrits en tête de `src/api.js` :

| Méthode | Endpoint | Réponse |
|---|---|---|
| GET | `/api/menu` | `{ categories, items }` |
| POST | `/api/orders` | `{ id, number, total, createdAt, status }` |
| GET | `/api/orders/:id/status` | `{ status, step?, robotProgress? }` — `processing · robot_picked · delivering · delivered` |
| GET | `/api/orders/:id/location` | `{ floor, zone: "A" \| "B" }` |
| POST | `/api/orders/:id/received` | `{ ok: true }` |
| POST | `/api/orders/:id/call-to-pay` | `{ ok: true }` |

Le statut est interrogé toutes les `POLL_INTERVAL_MS` (1,5 s). Pour passer en WebSocket/SSE plus tard, il suffit de remplacer `useOrderTracking` dans `store.jsx` : il doit seulement `dispatch({ type: "STATUS_UPDATE", payload })`.

## Ajouter une langue

Ajoutez un dictionnaire dans `src/i18n.js` (et dans `RTL_LANGS` si besoin). Les champs du menu acceptent `{ fr: "...", ar: "..." }`.

## Migration vers Vite + Tailwind + Framer Motion

Les fichiers `.jsx` sont déjà découpés par écran : remplacez les `window.X` par des `import/export`, les classes de `styles.css` peuvent être conservées telles quelles ou converties en utilitaires Tailwind (les tokens sont dans `:root`).
