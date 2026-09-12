import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/app_exception.dart';
import '../models/app_settings_model.dart';

/// Maneja la lectura/escritura de users/{userId}/settings/config.
class SettingsRepository {
  final FirebaseFirestore _firestore;

  SettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.settings)
        .doc(FirestorePaths.configDoc);
  }

  Stream<AppSettingsModel> watchSettings(String uid) {
    return _settingsDoc(uid).snapshots().map(
          (snap) => AppSettingsModel.fromMap(snap.data()),
        );
  }

  Future<AppSettingsModel> fetchSettings(String uid) async {
    try {
      final snap = await _settingsDoc(uid).get();
      return AppSettingsModel.fromMap(snap.data());
    } catch (_) {
      throw AppException.generic;
    }
  }

  Future<void> updateSettings(String uid, AppSettingsModel settings) async {
    try {
      await _settingsDoc(uid).set(settings.toMap(), SetOptions(merge: true));
    } catch (_) {
      throw AppException.generic;
    }
  }

  // Nota: deliberadamente NO existe un `updatePlan` aquí. El campo `plan`
  // de users/{userId} está bloqueado en firestore.rules para escrituras del
  // cliente — pasar a Premium debe hacerlo únicamente una Cloud Function
  // (Admin SDK) una vez que haya un cobro real verificado.
}
