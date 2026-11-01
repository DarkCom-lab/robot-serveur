/* =====================================================================
 * i18n.js — Traductions. Ajouter une langue = ajouter un dictionnaire.
 * Les langues RTL sont déclarées dans RTL_LANGS (dir="rtl" automatique).
 * ===================================================================== */
(function () {
  const fr = {
    "common.back": "Retour",
    "common.table": "Table {n}",
    "net.unstable": "Connexion instable — nouvelle tentative…",

    "welcome.greeting": "Bienvenue chez",
    "welcome.subtitle": "Commandez depuis votre table. Notre robot vous apporte tout, sans attendre.",
    "welcome.cta": "Voir le menu",
    "welcome.hint": "Paiement par carte ou en espèces, à la livraison",
    "welcome.noTable": "Table non détectée — scannez le QR code posé sur votre table",
    "welcome.scanned": "QR code scanné",

    "menu.title": "La carte",
    "menu.subtitle": "Préparé à la minute par nos baristas",
    "menu.soldOut": "Épuisé",
    "menu.signature": "Signature",
    "menu.errorTitle": "Impossible de charger le menu",
    "menu.errorText": "Vérifiez votre connexion puis réessayez.",
    "menu.retry": "Réessayer",
    "menu.add": "Ajouter {name}",
    "menu.removeOne": "Retirer un {name}",

    "cart.count_one": "{n} article",
    "cart.count_other": "{n} articles",
    "cart.view": "Voir le panier",

    "review.title": "Votre commande",
    "review.empty": "Votre panier est vide",
    "review.emptyText": "Parcourez la carte et ajoutez vos envies du moment.",
    "review.backToMenu": "Retour au menu",
    "review.addMore": "Ajouter d'autres articles",
    "review.subtotal": "Sous-total",
    "review.total": "Total",
    "review.deliverTo": "Livraison à la table",
    "review.confirm": "Confirmer ma commande",
    "review.remove": "Supprimer",
    "review.each": "{price} / unité",

    "payment.step": "Étape 2 sur 2",
    "payment.title": "Comment souhaitez-vous payer ?",
    "payment.subtitle": "Vous réglez au moment de la livraison.",
    "payment.card.title": "TPE (carte bancaire)",
    "payment.card.desc": "Un serveur vient avec le terminal de paiement quand vous l'appelez.",
    "payment.cash.title": "Espèces (Cash)",
    "payment.cash.desc": "Réglez en espèces auprès du serveur à la livraison.",
    "payment.submit": "Envoyer ma commande",
    "payment.sending": "Envoi en cours…",
    "payment.choose": "Choisissez un moyen de paiement",
    "payment.toPay": "À régler",

    "error.network": "Connexion impossible. Vérifiez le réseau et réessayez.",

    "waiting.title": "Votre commande est en cours de traitement",
    "waiting.elapsed": "Temps écoulé",
    "waiting.order": "Commande {n}",
    "waiting.summary": "Récapitulatif",

    "steps.received": "Reçue",
    "steps.preparing": "En préparation",
    "steps.delivering": "En livraison",
    "steps.receivedDesc": "Le bar a bien reçu votre commande",
    "steps.preparingDesc": "Nos baristas s'en occupent",
    "steps.deliveringDesc": "Le robot vous l'apporte",

    "pay.card": "Carte bancaire",
    "pay.cash": "Espèces",

    "robot.badge": "En route",
    "robot.title": "Le robot livre votre commande",
    "robot.floor": "Étage",
    "robot.zone": "Zone",
    "robot.bar": "Bar",
    "robot.picked": "Le robot récupère votre commande au bar…",
    "robot.hint": "Votre colis vous attend à l'étage {f}, zone {z}.",
    "robot.progress": "{p} % du trajet",

    "reception.title": "Votre commande est arrivée",
    "reception.text": "Récupérez votre colis sur le robot.",
    "reception.received": "J'ai reçu ma commande",
    "reception.callToPay": "Call to pay",
    "reception.callToPayDesc": "Appeler le serveur avec le terminal",
    "reception.calling": "Appel en cours…",
    "reception.called": "Serveur prévenu — il arrive avec le TPE",
    "reception.cashNote": "Le serveur passera encaisser {total} en espèces.",

    "thanks.title": "Merci !",
    "thanks.text": "Bonne dégustation. À très vite chez {cafe}.",
    "thanks.rate": "Comment s'est passée votre commande ?",
    "thanks.tag.fast": "Rapide",
    "thanks.tag.tasty": "Délicieux",
    "thanks.tag.robot": "Robot génial",
    "thanks.tag.friendly": "Service aimable",
    "thanks.send": "Envoyer mon avis",
    "thanks.sent": "Merci pour votre avis !",
    "thanks.new": "Nouvelle commande",
    "thanks.time": "Livrée en {t}"
  };

  const ar = {
    "common.back": "رجوع",
    "common.table": "طاولة {n}",
    "net.unstable": "الاتصال غير مستقر — إعادة المحاولة…",
    "welcome.greeting": "مرحبًا بكم في",
    "welcome.subtitle": "اطلب من طاولتك. الروبوت يوصل طلبك دون انتظار.",
    "welcome.cta": "عرض القائمة",
    "welcome.hint": "الدفع بالبطاقة أو نقدًا عند التسليم",
    "welcome.noTable": "لم يتم التعرف على الطاولة — امسح رمز QR الموجود على طاولتك",
    "welcome.scanned": "تم مسح رمز QR",
    "menu.title": "القائمة",
    "menu.subtitle": "يُحضَّر في الحال من طرف فريقنا",
    "menu.soldOut": "نفد",
    "menu.signature": "مميز",
    "menu.errorTitle": "تعذّر تحميل القائمة",
    "menu.errorText": "تحقق من الاتصال ثم أعد المحاولة.",
    "menu.retry": "إعادة المحاولة",
    "menu.add": "إضافة {name}",
    "menu.removeOne": "إزالة {name}",
    "cart.count_one": "{n} منتج",
    "cart.count_other": "{n} منتجات",
    "cart.view": "عرض السلة",
    "review.title": "طلبك",
    "review.empty": "سلتك فارغة",
    "review.emptyText": "تصفح القائمة وأضف ما تشتهيه.",
    "review.backToMenu": "العودة إلى القائمة",
    "review.addMore": "إضافة منتجات أخرى",
    "review.subtotal": "المجموع الفرعي",
    "review.total": "المجموع",
    "review.deliverTo": "التوصيل إلى الطاولة",
    "review.confirm": "تأكيد الطلب",
    "review.remove": "حذف",
    "review.each": "{price} / للوحدة",
    "payment.step": "الخطوة 2 من 2",
    "payment.title": "كيف تودّ الدفع؟",
    "payment.subtitle": "الدفع عند التسليم.",
    "payment.card.title": "جهاز الدفع (بطاقة بنكية)",
    "payment.card.desc": "يأتيك النادل بجهاز الدفع عند طلبه.",
    "payment.cash.title": "نقدًا (كاش)",
    "payment.cash.desc": "ادفع نقدًا للنادل عند التسليم.",
    "payment.submit": "إرسال الطلب",
    "payment.sending": "جارٍ الإرسال…",
    "payment.choose": "اختر طريقة الدفع",
    "payment.toPay": "المبلغ المستحق",
    "error.network": "تعذّر الاتصال. تحقق من الشبكة وأعد المحاولة.",
    "waiting.title": "طلبك قيد المعالجة",
    "waiting.elapsed": "الوقت المنقضي",
    "waiting.order": "الطلب {n}",
    "waiting.summary": "ملخص الطلب",
    "steps.received": "تم الاستلام",
    "steps.preparing": "قيد التحضير",
    "steps.delivering": "قيد التوصيل",
    "steps.receivedDesc": "استلمنا طلبك",
    "steps.preparingDesc": "فريقنا يحضّره الآن",
    "steps.deliveringDesc": "الروبوت في الطريق إليك",
    "pay.card": "بطاقة بنكية",
    "pay.cash": "نقدًا",
    "robot.badge": "في الطريق",
    "robot.title": "الروبوت يوصل طلبك",
    "robot.floor": "الطابق",
    "robot.zone": "المنطقة",
    "robot.bar": "البار",
    "robot.picked": "الروبوت يستلم طلبك من البار…",
    "robot.hint": "طلبك ينتظرك في الطابق {f}، المنطقة {z}.",
    "robot.progress": "{p}٪ من المسار",
    "reception.title": "وصل طلبك",
    "reception.text": "استلم طلبك من الروبوت.",
    "reception.received": "استلمت طلبي",
    "reception.callToPay": "طلب الدفع",
    "reception.callToPayDesc": "استدعاء النادل بجهاز الدفع",
    "reception.calling": "جارٍ الاستدعاء…",
    "reception.called": "تم إبلاغ النادل — قادم بجهاز الدفع",
    "reception.cashNote": "سيمر النادل لتحصيل {total} نقدًا.",
    "thanks.title": "شكرًا!",
    "thanks.text": "بالهناء والشفاء. نراك قريبًا في {cafe}.",
    "thanks.rate": "كيف كانت تجربتك؟",
    "thanks.tag.fast": "سريع",
    "thanks.tag.tasty": "لذيذ",
    "thanks.tag.robot": "روبوت رائع",
    "thanks.tag.friendly": "خدمة لطيفة",
    "thanks.send": "إرسال التقييم",
    "thanks.sent": "شكرًا على تقييمك!",
    "thanks.new": "طلب جديد",
    "thanks.time": "تم التوصيل في {t}"
  };

  const DICTS = { fr, ar };
  const RTL_LANGS = ["ar"];

  /** Traduit une clé, avec interpolation {var} et pluriel simple (_one/_other). */
  function translate(lang, key, vars) {
    vars = vars || {};
    let k = key;
    if (typeof vars.n === "number") k = key + (vars.n === 1 ? "_one" : "_other");
    const dict = DICTS[lang] || DICTS.fr;
    let str = dict[k] ?? DICTS.fr[k] ?? dict[key] ?? DICTS.fr[key] ?? key;
    return str.replace(/\{(\w+)\}/g, (_, v) => (vars[v] ?? `{${v}}`));
  }

  window.I18N = {
    translate,
    languages: Object.keys(DICTS),
    isRTL: (lang) => RTL_LANGS.includes(lang)
  };
})();
