import 'package:cloud_firestore/cloud_firestore.dart';

class ChatGroup {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final DateTime? createdAt;

  ChatGroup({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    this.createdAt,
  });

  factory ChatGroup.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final created = data['createdAt'] as Timestamp?;
    return ChatGroup(
      id: doc.id,
      name: data['name'] as String? ?? 'Grupo',
      ownerId: data['ownerId'] as String? ?? '',
      memberIds: (data['memberIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      createdAt: created?.toDate(),
    );
  }
}
