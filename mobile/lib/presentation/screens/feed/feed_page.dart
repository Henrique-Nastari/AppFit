// lib/presentation/screens/feed/feed_page.dart - ATUALIZADO (Treinos na Aba 1)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Imports de Navegação e Serviços
import '../../../application/auth/auth_service.dart';
import '../../widgets/feed/post_card.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

// Imports das Telas das Abas
import '../profile/profile_page.dart';
import '../workouts/workouts_page.dart';
import 'create_post_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _FeedContent(),           // Aba 0: Feed
      const WorkoutsPage(),           // Aba 1: Meus Treinos (SUBSTITUIU EXPLORAR)
      const _PlaceholderPage(title: "Progresso"), // Aba 2: Futuros gráficos (Placeholder)
      const ProfilePage(),            // Aba 3: Perfil
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onAddTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onAddTap: _onAddTapped,
      ),
    );
  }
}

// --- WIDGET DO CONTEÚDO DO FEED (MANTIDO IGUAL) ---
class _FeedContent extends StatefulWidget {
  const _FeedContent();

  @override
  State<_FeedContent> createState() => _FeedContentState();
}

class _FeedContentState extends State<_FeedContent> {
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
            padding: const EdgeInsets.only(bottom: 100),
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
    );
  }
}

// Página simples para abas em construção
class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text("$title (Em breve)", style: const TextStyle(fontSize: 18, color: Colors.grey))),
    );
  }
}