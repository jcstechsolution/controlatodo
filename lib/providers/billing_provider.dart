import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../repositories/billing_repository.dart';

enum BillingStatus { idle, loading, purchasePending, verifying, error }

/// Maneja el flujo completo de compra de Premium: consulta los productos de
/// la tienda, dispara compras, escucha el `purchaseStream` y verifica cada
/// compra contra la Cloud Function `verifyPlayPurchase` antes de darla por
/// buena. El plan del usuario (`plan` en Firestore) NUNCA se escribe desde
/// aquí ni desde ningún otro lugar del cliente — eso solo lo hace el
/// backend con el Admin SDK, tras verificar el recibo con Google.
///
/// Sigue el mismo patrón `bind(uid)` que ya usan `PaymentProvider` y
/// `SettingsProvider`.
class BillingProvider extends ChangeNotifier {
  final BillingRepository _repository;
  final FirebaseFunctions _functions;

  BillingProvider({
    BillingRepository? repository,
    FirebaseFunctions? functions,
  })  : _repository = repository ?? BillingRepository(),
        _functions = functions ?? FirebaseFunctions.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  String? _uid;

  List<ProductDetails> products = [];
  bool storeAvailable = true;
  BillingStatus status = BillingStatus.idle;
  String? errorMessage;

  // Un Future<bool> pendiente por productId, para poder devolver el
  // resultado de `buy()` aunque llegue de forma asíncrona por el stream.
  final Map<String, Completer<bool>> _pendingByProduct = {};
  Completer<bool>? _restoreCompleter;

  void bind(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _purchaseSubscription?.cancel();
    if (uid == null) {
      products = [];
      status = BillingStatus.idle;
      notifyListeners();
      return;
    }
    _purchaseSubscription = _repository.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[BILLING] error en purchaseStream: $e');
        }
      },
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    status = BillingStatus.loading;
    notifyListeners();
    try {
      storeAvailable = await _repository.isAvailable();
      if (!storeAvailable) {
        status = BillingStatus.idle;
        notifyListeners();
        return;
      }
      final response = await _repository.queryProducts();
      products = response.productDetails;
      if (kDebugMode && response.notFoundIDs.isNotEmpty) {
        // ignore: avoid_print
        print('[BILLING] productos no encontrados en la tienda: ${response.notFoundIDs}');
      }
      status = BillingStatus.idle;
      notifyListeners();
    } catch (e) {
      status = BillingStatus.error;
      errorMessage = 'No se pudo conectar con la tienda.';
      if (kDebugMode) {
        // ignore: avoid_print
        print('[BILLING] error cargando productos: $e');
      }
      notifyListeners();
    }
  }

  ProductDetails? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Inicia la compra de [productId]. El `Future` se resuelve más tarde,
  /// cuando el `purchaseStream` entrega el resultado ya verificado contra
  /// el backend (true = premium activado; false = falló o se canceló).
  Future<bool> buy(String productId) async {
    final product = productById(productId);
    if (product == null) {
      errorMessage = 'Ese plan no está disponible ahora mismo.';
      notifyListeners();
      return false;
    }
    errorMessage = null;
    status = BillingStatus.purchasePending;
    notifyListeners();
    final completer = Completer<bool>();
    _pendingByProduct[productId] = completer;
    try {
      await _repository.buy(product);
    } catch (e) {
      _pendingByProduct.remove(productId);
      status = BillingStatus.error;
      errorMessage = 'No se pudo iniciar la compra.';
      notifyListeners();
      return false;
    }
    return completer.future;
  }

  /// Restaura una compra Premium ya existente (misma cuenta de Google en
  /// otro dispositivo, o reinstalación). Si la tienda no encuentra ninguna
  /// compra que restaurar, no emite ningún evento — por eso se usa un
  /// timeout en vez de esperar indefinidamente.
  Future<bool> restore() async {
    errorMessage = null;
    status = BillingStatus.purchasePending;
    notifyListeners();
    _restoreCompleter = Completer<bool>();
    try {
      await _repository.restorePurchases();
    } catch (e) {
      _restoreCompleter = null;
      status = BillingStatus.error;
      errorMessage = 'No se pudieron restaurar las compras.';
      notifyListeners();
      return false;
    }
    final result = await _restoreCompleter!.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        status = BillingStatus.idle;
        errorMessage = 'No encontramos ninguna compra Premium asociada a esta cuenta.';
        notifyListeners();
        return false;
      },
    );
    _restoreCompleter = null;
    return result;
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          status = BillingStatus.purchasePending;
          notifyListeners();
          break;
        case PurchaseStatus.error:
          status = BillingStatus.error;
          errorMessage = purchase.error?.message ?? 'La compra no se completó.';
          _resolvePending(purchase.productID, false);
          notifyListeners();
          break;
        case PurchaseStatus.canceled:
          status = BillingStatus.idle;
          _resolvePending(purchase.productID, false);
          notifyListeners();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final ok = await _verifyAndComplete(purchase);
          if (purchase.status == PurchaseStatus.restored) {
            if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
              _restoreCompleter!.complete(ok);
            }
          }
          _resolvePending(purchase.productID, ok);
          break;
      }
    }
  }

  /// Verifica la compra contra `verifyPlayPurchase` y, sin importar el
  /// resultado, la completa localmente (requerido por el plugin para
  /// descartarla de la caché de compras pendientes del dispositivo — el
  /// reconocimiento real ante Google lo hace el backend, ver
  /// `functions/index.js`).
  Future<bool> _verifyAndComplete(PurchaseDetails purchase) async {
    status = BillingStatus.verifying;
    notifyListeners();
    var success = false;
    try {
      final callable = _functions.httpsCallable('verifyPlayPurchase');
      final result = await callable.call(<String, dynamic>{
        'productId': purchase.productID,
        'purchaseToken': purchase.verificationData.serverVerificationData,
      });
      final data = result.data;
      success = data is Map && data['success'] == true;
      if (!success) {
        errorMessage = 'No pudimos confirmar la compra. Intenta de nuevo.';
      }
    } catch (e) {
      success = false;
      errorMessage = 'No se pudo verificar la compra. Intenta de nuevo o contáctanos.';
      if (kDebugMode) {
        // ignore: avoid_print
        print('[BILLING] error verificando compra: $e');
      }
    }
    if (purchase.pendingCompletePurchase) {
      await _repository.completePurchase(purchase);
    }
    status = success ? BillingStatus.idle : BillingStatus.error;
    notifyListeners();
    return success;
  }

  void _resolvePending(String productId, bool value) {
    final completer = _pendingByProduct.remove(productId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(value);
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
