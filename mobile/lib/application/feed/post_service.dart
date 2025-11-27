// lib/application/feed/post_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> publishPost({
    required Map<String, dynamic> postData,
    File? imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    postData['userId'] = user.uid;
    postData['userDisplayName'] = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.email != null ? user.email!.split('@').first : 'Atleta');
    postData['userPhotoUrl'] = user.photoURL;
    postData['createdAt'] = FieldValue.serverTimestamp();

    // --- ADIÇÃO IMPORTANTE ---
    postData['commentCount'] = 0;
    postData['likeCount'] = 0;
    // -------------------------

    if (imageFile != null) {
      try {
        String imagePath = 'posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        UploadTask uploadTask = _storage.ref().child(imagePath).putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        postData['imageUrl'] = downloadUrl;
      } on FirebaseException catch (e) {
        throw Exception('Erro no upload da imagem: ${e.message}');
      }
    }

    await _firestore.collection('posts').add(postData);
  }
}