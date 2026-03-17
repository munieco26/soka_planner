import 'package:cloud_firestore/cloud_firestore.dart';

enum MemberRole { owner, editor, viewer }

class MemberModel {
  final String uid;
  final MemberRole role;
  final DateTime? joinedAt;
  final String? displayName;
  final String? email;

  const MemberModel({
    required this.uid,
    required this.role,
    this.joinedAt,
    this.displayName,
    this.email,
  });

  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberModel(
      uid: doc.id,
      role: MemberRole.values.firstWhere(
        (r) => r.name == (data['role'] as String? ?? 'viewer'),
        orElse: () => MemberRole.viewer,
      ),
      joinedAt: data['joinedAt'] != null
          ? (data['joinedAt'] as Timestamp).toDate()
          : null,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'role': role.name,
      'joinedAt': joinedAt != null
          ? Timestamp.fromDate(joinedAt!)
          : FieldValue.serverTimestamp(),
      'displayName': displayName,
      'email': email,
    };
  }
}
