// lib/post_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// A função principal para publicar um post.
  /// Ela recebe os dados do formulário (postData) e a imagem (imageFile).
  Future<void> publishPost({
    required Map<String, dynamic> postData,
    File? imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    // 1. Preenche os dados do usuário que estavam faltando no mapa
    postData['userId'] = user.uid;
    postData['userDisplayName'] = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.email != null ? user.email!.split('@').first : 'Atleta');
    postData['userPhotoUrl'] = user.photoURL;
    postData['createdAt'] = FieldValue.serverTimestamp();

    // 2. Faz o upload da imagem (se o usuário selecionou uma)
    if (imageFile != null) {
      try {
        // Define um caminho único para a imagem no Storage
        String imagePath = 'posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // Faz o upload do arquivo
        UploadTask uploadTask = _storage.ref().child(imagePath).putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;
        
        // Pega a URL de download da imagem
        String downloadUrl = await snapshot.ref.getDownloadURL();
        
        // 3. Adiciona a URL da imagem aos dados do post
        postData['imageUrl'] = downloadUrl;

      } on FirebaseException catch (e) {
        throw Exception('Erro no upload da imagem: ${e.message}');
      }
    }

    // 4. Salva o post completo (com ou sem a URL da imagem) no Firestore
    await _firestore.collection('posts').add(postData);
  }
}