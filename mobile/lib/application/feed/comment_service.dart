// lib/application/feed/comment_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- COMENTÁRIOS PRINCIPAIS ---

  Future<void> addComment({required String postId, required String content}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    // Dados do usuário para salvar no comentário (evita leituras extras)
    final String displayName = user.displayName ?? user.email?.split('@').first ?? 'Usuário';
    final String? photoUrl = user.photoURL;

    await _firestore.collection('posts').doc(postId).collection('comments').add({
      'userId': user.uid,
      'userName': displayName,
      'userPhotoUrl': photoUrl,
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'likes': [], // Array de UIDs de quem curtiu
      'likeCount': 0,
      'replyCount': 0,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteComment({required String postId, required String commentId}) async {
    await _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).delete();
  }

  // --- LIKES NOS COMENTÁRIOS ---

  Future<void> toggleCommentLike({required String postId, required String commentId, required List<dynamic> likes}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final docRef = _firestore.collection('posts').doc(postId).collection('comments').doc(commentId);

    if (likes.contains(uid)) {
      // Remover Like
      await docRef.update({
        'likes': FieldValue.arrayRemove([uid]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      // Adicionar Like
      await docRef.update({
        'likes': FieldValue.arrayUnion([uid]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  // --- RESPOSTAS (REPLIES) ---

  Future<void> addReply({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final String displayName = user.displayName ?? user.email?.split('@').first ?? 'Usuário';
    final String? photoUrl = user.photoURL;

    // Adiciona na subcoleção 'replies' do comentário
    await _firestore
        .collection('posts').doc(postId)
        .collection('comments').doc(commentId)
        .collection('replies')
        .add({
      'userId': user.uid,
      'userName': displayName,
      'userPhotoUrl': photoUrl,
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'likes': [],
      'likeCount': 0,
    });

    // Incrementa contador de respostas no comentário pai
    await _firestore
        .collection('posts').doc(postId)
        .collection('comments').doc(commentId)
        .update({'replyCount': FieldValue.increment(1)});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getReplies(String postId, String commentId) {
    return _firestore
        .collection('posts').doc(postId)
        .collection('comments').doc(commentId)
        .collection('replies')
        .orderBy('createdAt', descending: false) // Respostas geralmente são cronológicas (antigo -> novo)
        .snapshots();
  }

  Future<void> toggleReplyLike({required String postId, required String commentId, required String replyId, required List<dynamic> likes}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final docRef = _firestore
        .collection('posts').doc(postId)
        .collection('comments').doc(commentId)
        .collection('replies').doc(replyId);

    if (likes.contains(uid)) {
      await docRef.update({'likes': FieldValue.arrayRemove([uid]), 'likeCount': FieldValue.increment(-1)});
    } else {
      await docRef.update({'likes': FieldValue.arrayUnion([uid]), 'likeCount': FieldValue.increment(1)});
    }
  }

  Future<void> deleteReply({required String postId, required String commentId, required String replyId}) async {
    await _firestore
        .collection('posts').doc(postId)
        .collection('comments').doc(commentId)
        .collection('replies').doc(replyId)
        .delete();

    await _firestore
        .collection('posts').doc(postId)
        .collection('comments').doc(commentId)
        .update({'replyCount': FieldValue.increment(-1)});
  }
}