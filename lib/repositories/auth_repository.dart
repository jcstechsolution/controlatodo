import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firestore_paths.dart';
import '../core/constants/plan_limits.dart';
import '../core/utils/app_exception.dart';
import '../models/user_model.dart';

/// Encapsula toda la interacción con Firebase Authentication y crea/lee
/// el documento de perfil correspondiente en Firestore.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection(FirestorePaths.users).doc(uid);
  }

  Future<UserModel?> fetchUserProfile(String uid) async {
    try {
      final snapshot = await _userDoc(uid).get();
      if (!snapshot.exists) return null;
      return UserModel.fromSnapshot(snapshot);
    } catch (_) {
      throw AppException.generic;
    }
  }

  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(name.trim());

      final userModel = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        plan: UserPlan.free.id,
        createdAt: DateTime.now(),
      );

      await _userDoc(uid).set(userModel.toMap());
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AppException(_messageForAuthError(e.code));
    } catch (_) {
      throw AppException.generic;
    }
  }

  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      var profile = await fetchUserProfile(uid);
      profile ??= await _createMissingProfile(credential.user!);
      return profile;
    } on FirebaseAuthException catch (e) {
      throw AppException(_messageForAuthError(e.code));
    } catch (_) {
      throw AppException.generic;
    }
  }

  Future<UserModel> _createMissingProfile(User firebaseUser) async {
    final userModel = UserModel(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Usuario',
      email: firebaseUser.email ?? '',
      plan: UserPlan.free.id,
      createdAt: DateTime.now(),
    );
    await _userDoc(firebaseUser.uid).set(userModel.toMap());
    return userModel;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AppException(_messageForAuthError(e.code));
    } catch (_) {
      throw AppException.generic;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _messageForAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
      case 'network-request-failed':
        return 'Revisa tu conexión a internet e inténtalo de nuevo.';
      default:
        return 'Ha ocurrido un problema. Inténtalo nuevamente.';
    }
  }
}
