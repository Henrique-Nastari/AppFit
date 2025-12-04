import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chat_group.dart';
import '../../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _groups => _firestore.collection('groups');

  Stream<List<ChatGroup>> streamMyGroups() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _groups.where('memberIds', arrayContains: uid).snapshots().map(
          (snap) => snap.docs.map(ChatGroup.fromDoc).toList()
            ..sort((a, b) {
              final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bd.compareTo(ad);
            }),
        );
  }

  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario nao autenticado');

    final uniqueMembers = <String>{...memberIds, uid}.toList();

    final doc = await _groups.add({
      'name': name.trim(),
      'ownerId': uid,
      'memberIds': uniqueMembers,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<List<ChatMessage>> streamMessages(String groupId) {
    return _groups
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendMessage({
    required String groupId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario nao autenticado');
    final clean = text.trim();
    if (clean.isEmpty) return;

    await _groups.doc(groupId).collection('messages').add({
      'senderId': user.uid,
      'senderName': user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (user.email != null ? user.email!.split('@').first : 'Atleta'),
      'text': clean,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
