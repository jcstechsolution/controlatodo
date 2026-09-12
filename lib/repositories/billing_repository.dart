import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/constants/billing_constants.dart';

/// Encapsula el acceso a la tienda (Google Play / App Store) a través del
/// paquete federado `in_app_purchase`. No sabe nada de Firebase ni de
/// Firestore — solo habla con la tienda. La verificación de cada compra
/// contra el backend vive en `BillingProvider`, que es quien conoce el uid
/// del usuario actual.
class BillingRepository {
  final InAppPurchase _iap;

  BillingRepository({InAppPurchase? inAppPurchase})
      : _iap = inAppPurchase ?? InAppPurchase.instance;

  /// Actualizaciones de compras en curso (pendiente/comprada/error/
  /// restaurada). Un solo listener global, como recomienda el propio
  /// paquete — `BillingProvider` lo suscribe una única vez en `bind()`.
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetailsResponse> queryProducts() {
    return _iap.queryProductDetails(BillingConstants.allProductIds);
  }

  /// Las suscripciones se compran igual que un producto no-consumible: el
  /// paquete `in_app_purchase` no distingue un método aparte para
  /// suscripciones — la diferencia real la define cómo se configuró el
  /// producto en Play Console / App Store Connect.
  Future<void> buy(ProductDetails product) {
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  /// Descarta la compra de la cola local del dispositivo. Se llama siempre
  /// (haya sido válida o no tras la verificación del backend) para no
  /// dejarla atascada como "pendiente" en el equipo del usuario.
  Future<void> completePurchase(PurchaseDetails purchase) {
    return _iap.completePurchase(purchase);
  }
}
