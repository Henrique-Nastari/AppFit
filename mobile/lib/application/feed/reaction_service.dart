// lib/application/feed/reaction_service.dart - VERSÃO FINAL LIMPA

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReactionService {
  ReactionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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

  /// Alterna a reação do usuário com o [emoji] (LÓGICA REFATORADA).
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
      }); // Fim da Transação

    } on FirebaseException catch (e) {
      // Poderia logar o erro aqui se quisesse, sem printar para o usuário
      // logger.error("FirebaseException during reaction: ${e.code}", error: e);
      throw Exception('Erro de banco de dados ao reagir: ${e.message}');
    } catch (e, s) {
      // Poderia logar o erro aqui
      // logger.error("Generic error during reaction", error: e, stackTrace: s);
      throw Exception('Erro inesperado ao reagir: ${e.toString()}');
    }
  }
}