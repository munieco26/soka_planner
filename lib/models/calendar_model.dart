import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarModel {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String code;
  final int color;
  final DateTime? createdAt;
  final List<String> memberUids;

  const CalendarModel({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.code,
    required this.color,
    this.createdAt,
    this.memberUids = const [],
  });

  factory CalendarModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      ownerId: data['ownerId'] as String? ?? '',
      code: data['code'] as String? ?? '',
      color: data['color'] as int? ?? 0xFF2196F3,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      memberUids: List<String>.from(data['memberUids'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'code': code,
      'color': color,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'memberUids': memberUids,
    };
  }

  CalendarModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? code,
    int? color,
    DateTime? createdAt,
    List<String>? memberUids,
  }) {
    return CalendarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      code: code ?? this.code,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      memberUids: memberUids ?? this.memberUids,
    );
  }
}
