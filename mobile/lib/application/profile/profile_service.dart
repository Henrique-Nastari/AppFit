// lib/application/profile/profile_service.dart - ATUALIZADO (Com Notificação)

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../notifications/notification_service.dart'; // Import Adicionado

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService(); // Serviço instanciado

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _posts => _firestore.collection('posts');

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final docSnapshot = await _users.doc(userId).get();
      if (docSnapshot.exists) return docSnapshot.data();
      else return null;
    } catch (e) { rethrow; }
  }

  Future<void> updateUserData(Map<String, dynamic> dataToUpdate) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nenhum usuário logado.');
    final dataWithTimestamp = { ...dataToUpdate, 'updatedAt': FieldValue.serverTimestamp() };
    try { await _users.doc(user.uid).set(dataWithTimestamp, SetOptions(merge: true)); } catch (e) { rethrow; }
  }

  Future<String> uploadProfilePicture(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nenhum usuário logado.');
    try {
      final String imagePath = 'profile_pictures/${user.uid}.jpg';
      final ref = _storage.ref().child(imagePath);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      await user.updatePhotoURL(downloadUrl);
      await _users.doc(user.uid).update({'photoUrl': downloadUrl});
      return downloadUrl;
    } on FirebaseException catch (e) { rethrow; } catch (e) { rethrow; }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserPosts(String userId) {
    return _posts.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> followUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Login necessário.');
    final currentUserId = currentUser.uid;

    await _firestore.runTransaction((tx) async {
      final currentUserRef = _users.doc(currentUserId);
      final targetUserRef = _users.doc(targetUserId);
      tx.set(currentUserRef.collection('following').doc(targetUserId), {'timestamp': FieldValue.serverTimestamp()});
      tx.set(targetUserRef.collection('followers').doc(currentUserId), {'timestamp': FieldValue.serverTimestamp()});
      tx.update(currentUserRef, {'followingCount': FieldValue.increment(1)});
      tx.update(targetUserRef, {'followersCount': FieldValue.increment(1)});
    });

    // Enviar Notificação
    await _notificationService.sendNotification(
      targetUserId: targetUserId,
      type: 'follow',
      message: 'começou a seguir você.',
    );
  }

  Future<void> unfollowUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Login necessário.');
    final currentUserId = currentUser.uid;

    await _firestore.runTransaction((tx) async {
      final currentUserRef = _users.doc(currentUserId);
      final targetUserRef = _users.doc(targetUserId);
      tx.delete(currentUserRef.collection('following').doc(targetUserId));
      tx.delete(targetUserRef.collection('followers').doc(currentUserId));
      tx.update(currentUserRef, {'followingCount': FieldValue.increment(-1)});
      tx.update(targetUserRef, {'followersCount': FieldValue.increment(-1)});
    });
  }

  Stream<bool> isFollowing(String targetUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(false);
    return _users.doc(currentUser.uid).collection('following').doc(targetUserId).snapshots().map((snapshot) => snapshot.exists);
  }

  Stream<List<String>> getFollowingIdsStream(String userId) {
    return _users.doc(userId).collection('following').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Stream<List<String>> getFollowersIdsStream(String userId) {
    return _users.doc(userId).collection('followers').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<List<QueryDocumentSnapshot>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final result = await _users.where('displayName', isGreaterThanOrEqualTo: query).where('displayName', isLessThan: query + 'z').get();
    return result.docs;
  }
}