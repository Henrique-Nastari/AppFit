// lib/presentation/screens/feed/feed_page.dart - ATUALIZADO (com ValueKey)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../application/auth/auth_service.dart'; // Ajuste se necessário
import '../../widgets/feed/post_card.dart';        // Import do PostCard
import 'create_post_page.dart';                 // Import da tela de criação

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    // Busca as cores definidas no tema atual (claro ou escuro)
    final appBarTheme = Theme.of(context).appBarTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AppFit',
          style: GoogleFonts.lobster( // Ou a fonte que você escolheu
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: appBarTheme.backgroundColor,
        foregroundColor: appBarTheme.foregroundColor,
        elevation: appBarTheme.elevation,
        actions: [
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
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("Erro no StreamBuilder do Feed: ${snapshot.error}"); // Log para depuração
            return const Center(child: Text('Erro ao carregar posts.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum post ainda.\nSeja o primeiro!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final postDoc = posts[index];
              final postData = postDoc.data() as Map<String, dynamic>;
              final postId = postDoc.id; // Pega o ID do documento

              // *** ADIÇÃO DA KEY AQUI ***
              // Garante que cada PostCard tenha um estado único e seja
              // reconstruído corretamente ao rolar a lista.
              return PostCard(
                key: ValueKey(postId), // <-- ADICIONADO
                postId: postId,
                postData: postData,
              );
              // *** FIM DA ADIÇÃO DA KEY ***
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
        // Cores do FAB são definidas no tema em main.dart
      ),
    );
  }
}
