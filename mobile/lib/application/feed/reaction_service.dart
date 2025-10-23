import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service responsável por gerenciar reações (curtidas com emojis) em posts.
/// Mantém:
/// - No documento do post: um mapa `reactionCounts` com contagem por emoji.
/// - Na subcoleção `reactions` do post: um doc por usuário com o emoji atual.
class ReactionService {
  ReactionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Emojis padrão disponibilizados para reação.
  static const defaultEmojis = <String>['👍', '❤️', '🔥', '👏', '💪', '🤮'];

  DocumentReference<Map<String, dynamic>> _postRef(String postId) =>
      _firestore.collection('posts').doc(postId);

  DocumentReference<Map<String, dynamic>> _userReactionRef(
    String postId,
    String userId,
  ) => _postRef(postId).collection('reactions').doc(userId);

  /// Stream do mapa de contagens de reações do post.
  Stream<Map<String, int>> watchReactionCounts({required String postId}) {
    return _postRef(postId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return <String, int>{};
      final raw = data['reactionCounts'];
      if (raw is Map) {
        return raw.map<String, int>(
          (key, value) =>
              MapEntry(key.toString(), (value is num) ? value.toInt() : 0),
        );
      }
      return <String, int>{};
    });
  }

  /// Stream do emoji atual do usuário (ou null se não reagiu).
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

  /// Alterna a reação do usuário com o [emoji].
  ///
  /// Regras:
  /// - Se o usuário não reagiu, cria reação com esse emoji e incrementa contagem.
  /// - Se já reagiu com o mesmo emoji, remove a reação e decrementa contagem.
  /// - Se já reagiu com emoji diferente, troca para o novo emoji (decrementa antigo, incrementa novo).
  Future<void> toggleReaction({
    required String postId,
    required String emoji,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }
    final userId = user.uid;

    await _firestore.runTransaction((tx) async {
      final postRef = _postRef(postId);
      final reactionRef = _userReactionRef(postId, userId);

      final postSnap = await tx.get(postRef);
      final userReactionSnap = await tx.get(reactionRef);

      String? currentEmoji;
      if (userReactionSnap.exists) {
        final data = userReactionSnap.data();
        final e = data?['emoji'];
        if (e is String) currentEmoji = e;
      }

      // Atualizações na contagem (nested fields)
      final updates = <String, dynamic>{};

      if (currentEmoji == null) {
        // Criar reação com [emoji]
        updates['reactionCounts.$emoji'] = FieldValue.increment(1);
        tx.set(reactionRef, {
          'emoji': emoji,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (currentEmoji == emoji) {
        // Remover reação
        updates['reactionCounts.$emoji'] = FieldValue.increment(-1);
        tx.delete(reactionRef);
      } else {
        // Trocar reação
        updates['reactionCounts.$currentEmoji'] = FieldValue.increment(-1);
        updates['reactionCounts.$emoji'] = FieldValue.increment(1);
        tx.set(reactionRef, {
          'emoji': emoji,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Garante que o campo exista como mapa mesmo se não existir ainda
      if (!postSnap.exists) {
        tx.set(postRef, {
          'reactionCounts': {emoji: currentEmoji == emoji ? 0 : 1},
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      tx.update(postRef, updates);
    });
  }
}
