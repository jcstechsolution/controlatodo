import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/plan_limits.dart';

/// Datos de perfil del usuario, almacenados en users/{userId}.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String plan;
  final DateTime createdAt;

  /// Producto de suscripción activo (`premium_monthly`/`premium_annual`) y
  /// fecha en que renueva/expira. Ambos son escritos ÚNICAMENTE por la
  /// Cloud Function `verifyPlayPurchase` tras verificar la compra contra
  /// Google Play (ver `firestore.rules` — el cliente no puede tocarlos).
  /// Opcionales y con default `null` para que los documentos ya existentes
  /// (creados antes de que existiera Premium real) se sigan leyendo sin
  /// problema.
  final String? premiumProductId;
  final DateTime? premiumExpiryTime;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.plan,
    required this.createdAt,
    this.premiumProductId,
    this.premiumExpiryTime,
  });

  UserPlan get planEnum => UserPlanX.fromId(plan);
  bool get isPremium => planEnum == UserPlan.premium;

  UserModel copyWith({
    String? name,
    String? email,
    String? plan,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      plan: plan ?? this.plan,
      createdAt: createdAt,
      premiumProductId: premiumProductId,
      premiumExpiryTime: premiumExpiryTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'plan': plan,
      'createdAt': Timestamp.fromDate(createdAt),
      // Los campos premium* NUNCA se escriben desde el cliente (las reglas
      // de Firestore los bloquean explícitamente) — por eso no se incluyen
      // aquí. Este toMap() hoy solo se usa al crear la cuenta, cuando esos
      // campos todavía no existen.
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      plan: map['plan'] as String? ?? UserPlan.free.id,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      premiumProductId: map['premiumProductId'] as String?,
      premiumExpiryTime: (map['premiumExpiryTime'] as Timestamp?)?.toDate(),
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromMap(doc.id, doc.data() ?? const {});
  }
}
