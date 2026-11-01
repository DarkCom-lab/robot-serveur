# ☕ Fabtino Serveur — Application Mobile Flutter (Robot Livreur de Café)

Application mobile tactile dédiée aux serveurs de salle d'un café équipé d'un robot livreur autonome à 3 étages (modèle Pudu/Fabtino).

L'application permet au personnel de service de surveiller en direct l'état du robot et de lui déléguer rapidement des missions de livraison de commandes aux tables, le tout utilisable confortablement **d'une seule main** pendant le service.

---

## 📱 Caractéristiques Clés & Ergonomie

- **Écran 0 (Connexion) :** code PIN à 4 chiffres.
- **Écran 1 (État du robot) :**
  - La **photo du robot**, la batterie et son statut.
  - Un gros bandeau **LIBRE** (vert) ou **NON LIBRE** (rouge, avec la raison).
  - Le robot vu de face : **3 étages, chacun coupé en 2 parties (Gauche / Droite)**.
    Vert = partie libre, rouge = partie occupée (avec le numéro de table).
  - Le bouton **« Passer une commande »** n'apparaît **que si le robot est libre**.
    Robot non libre (6 parties occupées, batterie < 20 %, hors ligne, en charge, en erreur) : pas de bouton, juste la raison.
  - Les commandes « gardées pour plus tard » avec un bouton **« Envoyer le robot maintenant »**.
- **Écran 2 (Passer une commande) — 3 étapes :**
  1. **Plateau** : toucher une partie verte du robot (ou « Choisir pour moi »).
  2. **Client** : toucher sa table sur le **plan du café** (les tables avec une commande en attente sont actives).
  3. **Paiement et départ** : **TPE / Sans TPE**, puis **Partir maintenant / Garder pour plus tard**
     (le robot range la commande et attend votre ordre de départ).
- **Écran 3 (Suivi) :** progression En attente ➔ Prise en charge ➔ En livraison ➔ Livrée.

---

## 🧱 Stack Technique

- **Flutter 3.x / Dart 3.x**
- **Material 3** avec thème Café Sombre (Espresso Roast, Ambre torréfié, Vert émeraude)
- **State Management :** Riverpod (`flutter_riverpod`)
- **Navigation :** GoRouter (`go_router`) avec gardes d'authentification et de fonctionnalités
- **Architecture :** *Feature-First* (`lib/features/<feature>/{domain,data,ui}`)
- **Stockage Sécurisé :** `flutter_secure_storage` (chiffrement KeyStore Android / Keychain iOS)
- **Réseau :** Client HTTP REST + Client WebSocket avec reconnexion automatique
- **Internationalisation :** Textes en français, structure RTL prête pour l'arabe

---

## 📂 Structure des Dossiers

```
app_serveur_flutter/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── test/
│   ├── robot_availability_test.dart   # Tests seuils batterie, robot plein 6/6, etc.
│   ├── placement_logic_test.dart      # Tests parties Gauche/Droite et choix automatique
│   └── features_config_test.dart      # Tests matrice permissions Serveur vs Gérant
└── lib/
    ├── main.dart                      # Point d'entrée avec ProviderScope et i18n
    ├── core/
    │   ├── config/
    │   │   ├── app_config.dart        # Configuration globale (baseUrl, useMock, seuils)
    │   │   └── features_config.dart   # Matrice unique des Feature Flags & Permissions
    │   ├── constants/
    │   │   ├── app_colors.dart        # Palette café sombre et indicateurs vifs
    │   │   ├── app_dimensions.dart    # Ergonomie (cibles tactiles >= 48px, hauteurs)
    │   │   ├── app_typography.dart    # Typographie à fort contraste
    │   │   └── app_theme.dart         # Configuration Material 3
    │   ├── i18n/
    │   │   └── app_strings.dart       # Textes FR et support RTL
    │   ├── network/
    │   │   ├── api_client.dart        # Client HTTP REST avec token JWT automatique
    │   │   └── websocket_client.dart  # Client WebSocket temps réel avec reconnexion
    │   ├── storage/
    │   │   └── secure_storage_service.dart # Stockage chiffré des jetons et sessions
    │   ├── utils/
    │   │   └── haptic_feedback_helper.dart # Retours haptiques sur les actions
    │   └── router/
    │       └── app_router.dart        # Routes GoRouter avec redirections gardées
    └── features/
        ├── auth/
        │   ├── domain/                # UserRole, AuthState
        │   ├── data/                  # AuthRepository, MockAuthRepository, HttpAuthRepository
        │   └── ui/                    # PinLoginScreen, PinKeypadWidget, AuthController
        ├── robot/
        │   ├── domain/                # RobotFloor, ZoneSlot, RobotStatus, RobotStateModel
        │   ├── data/                  # RobotRepository, MockRobotRepository, HttpRobotRepository
        │   └── ui/                    # RobotStatusScreen, RobotSchematicWidget, BatteryIndicator...
        └── tasks/
            ├── domain/                # PendingOrder, PlacementChoice, RobotTask, DeliveryStep
            ├── data/                  # OrdersRepository, TasksRepository (Mock & HTTP)
            └── ui/                    # TaskWizardScreen, TaskTrackingScreen, Widgets...
```

---

## 🚀 Instructions pour Lancer l'Application

### 1. Prérequis
- Flutter SDK (≥ 3.10.0) et Dart (≥ 3.0.0)
- Un émulateur Android, un simulateur iOS ou un appareil physique connecté.

### 2. Récupérer les dépendances
```bash
cd app_serveur_flutter
flutter pub get
```

### 3. Exécuter les tests unitaires
```bash
flutter test
```
*Les tests valident automatiquement :*
- La désactivation du bouton si batterie < 20% ou si robot plein (3/3).
- La détection d'étage partiel (Zone A prise, Zone B libre).
- L'algorithme de placement optimal automatique.
- La matrice des feature flags et des permissions par rôle.

### 4. Lancer l'application
```bash
flutter run
```

### 5. Codes PIN de test (Écran de connexion)
- **Serveur (waiter) :** `1234` ➔ Accès à l'application serveur restreinte.
- **Gérant (manager) :** `9999` ➔ Profil avec toutes les fonctionnalités débloquées.

---

## 🔌 Comment Brancher les Vrais Endpoints Backend

Le basculement du mode **MOCK** au serveur **RÉEL** s'effectue dans **un seul fichier** :  
👉 [`lib/core/config/app_config.dart`](file:///lib/core/config/app_config.dart)

```dart
class AppConfig {
  // 1. Passez cette valeur à false :
  static const bool useMock = false;

  // 2. Renseignez l'adresse de votre serveur backend réel :
  static const String apiBaseUrl = 'https://mon-serveur-cafe.com';
  static const String wsUrl = 'wss://mon-serveur-cafe.com/ws/robot';

  // 3. Ajustez le seuil critique de batterie si nécessaire (ex: 15%) :
  static const int lowBatteryThreshold = 20;
}
```

### Correspondance des Endpoints API

| Méthode | Endpoint | Description | Implémentation prête |
|---|---|---|---|
| `POST` | `/api/auth/login` | Connexion par PIN ➔ `{ token, role }` | `HttpAuthRepository` |
| `GET` | `/api/robot/status` | Statut robot & étages ➔ `{ status, battery, floors: [...] }` | `HttpRobotRepository` |
| `GET` | `/api/orders?status=pending` | Commandes en attente de livraison | `HttpOrdersRepository` |
| `POST` | `/api/robot/tasks` | Création mission ➔ `{ orderId, floor, zone, paymentMode }` | `HttpTasksRepository` |
| `GET` | `/api/robot/tasks/:id` | Suivi de la tâche en cours | `HttpTasksRepository` |
| `WS` | `/ws/robot` | Flux WebSocket d'événements temps réel | `WebSocketClient` |

*Toutes les requêtes HTTP injectent automatiquement le jeton d'authentification JWT chiffré dans le header `Authorization: Bearer <token>`.*

---

## 🚩 Comment Activer une Nouvelle Fonctionnalité via les Flags

Toutes les permissions et activations sont centralisées dans :  
👉 [`lib/core/config/features_config.dart`](file:///lib/core/config/features_config.dart)

### Exemple : Activer "Annuler une tâche" ou "Arrêt d'urgence" pour le serveur

Dans `FeaturesConfig._permissionsMatrix`, changez simplement le booléen pour `UserRole.waiter` :

```dart
// Avant :
AppFeature.cancelTask: {
  UserRole.waiter: false, // DÉSACTIVÉ
  UserRole.manager: true,
},

// Après activation pour le serveur :
AppFeature.cancelTask: {
  UserRole.waiter: true,  // ACTIVÉ SANS RÉÉCRIRE L'APP !
  UserRole.manager: true,
},
```

Pour connecter l'écran dans la navigation, ajoutez la route correspondante dans `app_router.dart` :
```dart
GoRoute(
  path: '/cancel-task',
  builder: (context, state) => const CancelTaskScreen(),
),
```

### 🔒 Sécurité Côté Serveur (Zéro-Confiance)
Bien que l'application cliente masque les éléments d'interface non autorisés, l'API backend vérifie systématiquement le rôle contenu dans le JWT (`waiter` vs `manager`) sur chaque endpoint protégé. Toute requête directe non autorisée est rejetée avec un code HTTP 403 Forbidden.
