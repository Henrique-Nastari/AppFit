// lib/application/feed/comment_service.dart - ATUALIZADO (Com Notificação)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../notifications/notification_service.dart'; // Import Adicionado

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService(); // Serviço instanciado

  Future<void> addComment({required String postId, required String content}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    if (content.trim().isEmpty) return;

    // 1. Buscar dono do post
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    final postOwnerId = postDoc.data()?['userId'];

    final String displayName = user.displayName ?? user.email?.split('@').first ?? 'Usuário';
    final String? photoUrl = user.photoURL;

    await _firestore.collection('posts').doc(postId).collection('comments').add({
      'userId': user.uid,
      'userName': displayName,
      'userPhotoUrl': photoUrl,
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'likes': [],
      'likeCount': 0,
      'replyCount': 0,
    });

    await _firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });

    // 2. Enviar Notificação
    if (postOwnerId != null) {
      await _notificationService.sendNotification(
        targetUserId: postOwnerId,
        type: 'comment',
        message: 'comentou: "$content"',
        postId: postId,
      );
    }
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
    await _firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  Future<void> toggleCommentLike({required String postId, required String commentId, required List<dynamic> likes}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final docRef = _firestore.collection('posts').doc(postId).collection('comments').doc(commentId);

    if (likes.contains(uid)) {
      await docRef.update({'likes': FieldValue.arrayRemove([uid]), 'likeCount': FieldValue.increment(-1)});
    } else {
      await docRef.update({'likes': FieldValue.arrayUnion([uid]), 'likeCount': FieldValue.increment(1)});
    }
  }

  Future<void> addReply({required String postId, required String commentId, required String content}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    // Buscar dono do comentário pai para notificar (simplificação)
    final commentDoc = await _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).get();
    final commentOwnerId = commentDoc.data()?['userId'];

    final String displayName = user.displayName ?? user.email?.split('@').first ?? 'Usuário';
    final String? photoUrl = user.photoURL;

    await _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).collection('replies').add({
      'userId': user.uid,
      'userName': displayName,
      'userPhotoUrl': photoUrl,
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'likes': [],
      'likeCount': 0,
    });

    await _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).update({'replyCount': FieldValue.increment(1)});

    // Notificar dono do comentário
    if (commentOwnerId != null) {
      await _notificationService.sendNotification(
        targetUserId: commentOwnerId,
        type: 'comment',
        message: 'respondeu seu comentário: "$content"',
        postId: postId,
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getReplies(String postId, String commentId) {
    return _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).collection('replies').orderBy('createdAt', descending: false).snapshots();
  }

  Future<void> toggleReplyLike({required String postId, required String commentId, required String replyId, required List<dynamic> likes}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final docRef = _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).collection('replies').doc(replyId);
    if (likes.contains(uid)) {
      await docRef.update({'likes': FieldValue.arrayRemove([uid]), 'likeCount': FieldValue.increment(-1)});
    } else {
      await docRef.update({'likes': FieldValue.arrayUnion([uid]), 'likeCount': FieldValue.increment(1)});
    }
  }

  Future<void> deleteReply({required String postId, required String commentId, required String replyId}) async {
    await _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).collection('replies').doc(replyId).delete();
    await _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).update({'replyCount': FieldValue.increment(-1)});
  }
}