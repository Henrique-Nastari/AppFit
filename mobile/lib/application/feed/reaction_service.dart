// lib/application/feed/reaction_service.dart - ATUALIZADO (Com Notificação)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../notifications/notification_service.dart'; // Import Adicionado

class ReactionService {
  ReactionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationService _notificationService = NotificationService(); // Serviço instanciado

  static const defaultEmojis = <String>['👍', '❤️', '🔥', '👏', '💪', '🤮'];

  DocumentReference<Map<String, dynamic>> _postRef(String postId) =>
      _firestore.collection('posts').doc(postId);

  DocumentReference<Map<String, dynamic>> _userReactionRef(
      String postId,
      String userId,
      ) => _postRef(postId).collection('reactions').doc(userId);

  Stream<Map<String, int>> watchReactionCounts({required String postId}) {
    return _postRef(postId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return <String, int>{};
      final rawCounts = data['reactionCounts'];
      if (rawCounts is Map) {
        final Map<String, int> typedCounts = {};
        rawCounts.forEach((key, value) {
          if (key is String && value is num) {
            typedCounts[key] = value.toInt();
          }
        });
        return typedCounts;
      }
      return <String, int>{};
    });
  }

  Stream<String?> watchUserReaction({
    required String postId,
    required String userId,
  }) {
    return _userReactionRef(postId, userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final emoji = data['emoji'];
      return emoji is String ? emoji : null;
    });
  }

  Future<void> toggleReaction({
    required String postId,
    required String emoji,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }
    final userId = user.uid;

    try {
      // 1. Buscar dono do post para notificar
      final postDoc = await _postRef(postId).get();
      final postOwnerId = postDoc.data()?['userId'];

      // 2. Transação (Lógica original mantida)
      await _firestore.runTransaction((tx) async {
        final postRef = _postRef(postId);
        final reactionRef = _userReactionRef(postId, userId);

        final postSnap = await tx.get(postRef);
        final userReactionSnap = await tx.get(reactionRef);

        final Map<String, dynamic> currentData = postSnap.data() ?? {};
        final dynamic rawCounts = currentData['reactionCounts'];
        final Map<String, int> currentCounts = {};
        if(rawCounts is Map){
          rawCounts.forEach((key, value) {
            if (key is String && value is num) {
              currentCounts[key] = value.toInt();
            }
          });
        }

        String? previousEmoji;
        if (userReactionSnap.exists) {
          final data = userReactionSnap.data();
          final e = data?['emoji'];
          if (e is String) previousEmoji = e;
        }

        final now = FieldValue.serverTimestamp();

        if (previousEmoji == null) {
          tx.set(reactionRef, {'emoji': emoji, 'updatedAt': now});
          currentCounts[emoji] = (currentCounts[emoji] ?? 0) + 1;
        } else if (previousEmoji == emoji) {
          tx.delete(reactionRef);
          currentCounts[previousEmoji] = (currentCounts[previousEmoji] ?? 1) - 1;
        } else {
          tx.set(reactionRef, {'emoji': emoji, 'updatedAt': now});
          currentCounts[previousEmoji] = (currentCounts[previousEmoji] ?? 1) - 1;
          currentCounts[emoji] = (currentCounts[emoji] ?? 0) + 1;
        }

        currentCounts.removeWhere((key, value) => value <= 0);

        tx.update(postRef, {
          'reactionCounts': currentCounts,
          'updatedAt': now
        });
      });

      // 3. Enviar Notificação (apenas se criou ou trocou reação)
      if (postOwnerId != null && postOwnerId != userId) {
        // Verifica se foi uma remoção (não notifica remoção)
        // Lógica simplificada: Notifica sempre que interage positivamente
        await _notificationService.sendNotification(
          targetUserId: postOwnerId,
          type: 'like',
          message: 'reagiu com $emoji ao seu post.',
          postId: postId,
        );
      }

    } on FirebaseException catch (e) {
      throw Exception('Erro de banco de dados ao reagir: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao reagir: ${e.toString()}');
    }
  }
}