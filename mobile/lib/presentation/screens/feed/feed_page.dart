// lib/presentation/screens/feed/feed_page.dart - ATUALIZADO (com Botão de Perfil)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../application/auth/auth_service.dart';
import '../../widgets/feed/post_card.dart';
import 'create_post_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final appBarTheme = Theme.of(context).appBarTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AppFit',
          style: GoogleFonts.lobster(
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: appBarTheme.backgroundColor,
        foregroundColor: appBarTheme.foregroundColor,
        elevation: appBarTheme.elevation,
        actions: [
          // --- 1. BOTÃO DE PERFIL ADICIONADO ---
          IconButton(
            tooltip: 'Meu Perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // 2. NAVEGAÇÃO PELA ROTA
              Navigator.of(context).pushNamed('/profile');
            },
          ),
          // --- FIM DA ADIÇÃO ---

          IconButton(
            tooltip: 'Meus treinos',
            icon: const Icon(Icons.fitness_center),
            onPressed: () {
              Navigator.of(context).pushNamed('/workouts');
            },
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ... (StreamBuilder e ListView.builder permanecem os mesmos) ...
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) { /* ... (código de erro igual) ... */ }
          if (snapshot.connectionState == ConnectionState.waiting) { /* ... (loading igual) ... */ }
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) { /* ... (feed vazio igual) ... */ }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final postDoc = posts[index];
              final postData = postDoc.data() as Map<String, dynamic>;
              final postId = postDoc.id;

              return PostCard(
                key: ValueKey(postId),
                postId: postId,
                postData: postData,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreatePostPage()),
          );
        },
        tooltip: 'Novo Registro',
        child: const Icon(Icons.add),
      ),
    );
  }
}