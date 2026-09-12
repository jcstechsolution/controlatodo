import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/plan_limits.dart';

/// Datos de perfil del usuario, almacenados en users/{userId}.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String plan;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.plan,
    required this.createdAt,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'plan': plan,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      plan: map['plan'] as String? ?? UserPlan.free.id,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromMap(doc.id, doc.data() ?? const {});
  }
}
