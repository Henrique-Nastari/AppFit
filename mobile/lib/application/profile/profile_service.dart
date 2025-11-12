// lib/application/profile/profile_service.dart - COMPLETO E CORRIGIDO

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  /// Busca os dados de um usuário específico uma única vez.
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final docSnapshot = await _users.doc(userId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      } else {
        return null;
      }
    } catch (e) {
      // O erro é relançado para a UI tratar (ex: mostrar SnackBar)
      rethrow;
    }
  }

  /// Retorna um Stream com a lista de posts de um usuário específico.
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserPosts(String userId) {
    // CORREÇÃO: Este método usa _posts e retorna um Stream,
    // corrigindo os erros "unused _posts" e "stream body might complete"
    return _posts
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Atualiza os dados do usuário logado no Firestore.
  Future<void> updateUserData(Map<String, dynamic> dataToUpdate) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado para atualizar.');
    }

    final dataWithTimestamp = {
      ...dataToUpdate,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _users.doc(user.uid).set(dataWithTimestamp, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Faz upload de uma nova foto de perfil, atualiza o Firestore e o Auth.
  Future<String> uploadProfilePicture(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado.');
    }

    try {
      final String imagePath = 'profile_pictures/${user.uid}.jpg';
      final ref = _storage.ref().child(imagePath);

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Atualiza ambos os locais
      await user.updatePhotoURL(downloadUrl);
      await _users.doc(user.uid).update({'photoUrl': downloadUrl});

      return downloadUrl;

    } on FirebaseException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}