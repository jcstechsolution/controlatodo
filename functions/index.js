/**
 * Cloud Functions de ControlaTodo.
 *
 * verifyPlayPurchase: función callable que el cliente invoca justo después
 * de comprar (o restaurar) una suscripción Premium en Google Play. Verifica
 * el token de compra contra la Android Publisher API y, SOLO si es válido,
 * activa el plan Premium del usuario escribiendo en Firestore con el Admin
 * SDK. El cliente nunca puede escribir el campo `plan` directamente — las
 * reglas de Firestore (firestore.rules) lo bloquean a propósito.
 *
 * checkExpiredSubscriptions: función programada (diaria) que re-verifica
 * cada suscripción Premium activa contra Google Play, para detectar
 * renovaciones y cancelaciones sin depender de que el usuario abra la app.
 *
 * NOTA para quien retome este código: los nombres exactos de los métodos de
 * la Android Publisher API (`purchases.subscriptionsv2.get`, el endpoint de
 * `acknowledge`, etc.) conviene reconfirmarlos contra la documentación
 * vigente de Google y la versión de `googleapis` instalada al momento de
 * desplegar — Google ha ido migrando esta API entre v1 y v2 y los nombres
 * pueden variar. Probar con una compra de prueba real (ver el checklist de
 * configuración) antes de confiar en que esto funciona tal cual.
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const { google } = require('googleapis');

admin.initializeApp();

const ANDROID_PACKAGE_NAME = 'com.jcs.controlatodo';
const KNOWN_PRODUCT_IDS = ['premium_monthly', 'premium_annual'];

let _androidPublisher = null;

/**
 * Cliente autenticado contra la Android Publisher API, usando las
 * credenciales POR DEFECTO de la cuenta de servicio de esta Cloud Function
 * (Application Default Credentials). No requiere ningún archivo de llave
 * JSON: se le da acceso a esta misma cuenta de servicio desde Play Console
 * → Usuarios y permisos (ver el checklist de configuración externa).
 */
async function androidPublisher() {
  if (_androidPublisher) return _androidPublisher;
  const auth = new google.auth.GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  _androidPublisher = google.androidpublisher({ version: 'v3', auth });
  return _androidPublisher;
}

/**
 * Consulta el estado real de una suscripción ante Google Play.
 * Devuelve { active, expiryTimeMillis } o null si el token no es válido o
 * no corresponde a este productId.
 */
async function fetchSubscriptionState(productId, purchaseToken) {
  const publisher = await androidPublisher();
  const res = await publisher.purchases.subscriptionsv2.get({
    packageName: ANDROID_PACKAGE_NAME,
    token: purchaseToken,
  });
  const data = res.data;
  const lineItem = (data.lineItems || []).find(
    (item) => item.productId === productId,
  );
  if (!lineItem) return null;

  const state = data.subscriptionState;
  const active =
    state === 'SUBSCRIPTION_STATE_ACTIVE' ||
    state === 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD';
  const expiryTimeMillis = lineItem.expiryTime
    ? new Date(lineItem.expiryTime).getTime()
    : null;

  return { active, expiryTimeMillis };
}

/**
 * Reconoce la compra ante Google (obligatorio dentro de las primeras 72
 * horas o Google la reembolsa y revoca automáticamente). Se hace del lado
 * del servidor para no depender de que el cliente siga vivo y llame a
 * `completePurchase()` a tiempo. Si ya estaba reconocida, la API devuelve
 * un error que se ignora a propósito (no es un fallo real).
 */
async function acknowledgeSubscription(productId, purchaseToken) {
  try {
    const publisher = await androidPublisher();
    await publisher.purchases.subscriptions.acknowledge({
      packageName: ANDROID_PACKAGE_NAME,
      subscriptionId: productId,
      token: purchaseToken,
      requestBody: {},
    });
  } catch (err) {
    logger.info('acknowledge() ignorado (probablemente ya estaba reconocida)', {
      message: err.message,
    });
  }
}

exports.verifyPlayPurchase = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Debes iniciar sesión.');
  }
  const uid = request.auth.uid;
  const { productId, purchaseToken } = request.data || {};

  if (!KNOWN_PRODUCT_IDS.includes(productId) || !purchaseToken) {
    throw new HttpsError('invalid-argument', 'Compra inválida.');
  }

  const db = admin.firestore();

  // Anti-abuso: este token de compra no puede estar ya asociado a OTRO uid
  // (evita que el mismo pago de Play active Premium en dos cuentas).
  const tokenRef = db.collection('processedPurchaseTokens').doc(purchaseToken);
  const tokenSnap = await tokenRef.get();
  if (tokenSnap.exists && tokenSnap.data().uid !== uid) {
    logger.warn('Token de compra reutilizado por otro uid', { uid, productId });
    throw new HttpsError('already-exists', 'Esta compra ya está asociada a otra cuenta.');
  }

  let state;
  try {
    state = await fetchSubscriptionState(productId, purchaseToken);
  } catch (err) {
    logger.error('Error consultando Android Publisher API', err);
    throw new HttpsError('internal', 'No se pudo verificar la compra con Google Play.');
  }

  if (!state || !state.active) {
    throw new HttpsError('failed-precondition', 'La suscripción no está activa.');
  }

  const userRef = db.collection('users').doc(uid);
  const batch = db.batch();
  batch.update(userRef, {
    plan: 'premium',
    premiumProductId: productId,
    premiumExpiryTime: admin.firestore.Timestamp.fromMillis(state.expiryTimeMillis),
    premiumPurchaseToken: purchaseToken,
    premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  batch.set(tokenRef, {
    uid,
    productId,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await batch.commit();

  await acknowledgeSubscription(productId, purchaseToken);

  return { success: true };
});

exports.checkExpiredSubscriptions = onSchedule('every 24 hours', async () => {
  const db = admin.firestore();
  const snap = await db.collection('users').where('plan', '==', 'premium').get();

  const updates = [];
  for (const doc of snap.docs) {
    const data = doc.data();
    const purchaseToken = data.premiumPurchaseToken;
    const productId = data.premiumProductId;
    if (!purchaseToken || !productId) continue;

    try {
      const state = await fetchSubscriptionState(productId, purchaseToken);
      if (state && state.active) {
        updates.push(
          doc.ref.update({
            premiumExpiryTime: admin.firestore.Timestamp.fromMillis(state.expiryTimeMillis),
          }),
        );
      } else {
        updates.push(
          doc.ref.update({
            plan: 'free',
            premiumProductId: admin.firestore.FieldValue.delete(),
            premiumExpiryTime: admin.firestore.FieldValue.delete(),
            premiumPurchaseToken: admin.firestore.FieldValue.delete(),
          }),
        );
      }
    } catch (err) {
      logger.error(`No se pudo re-verificar la suscripción de ${doc.id}`, err);
    }
  }
  await Promise.all(updates);
});
