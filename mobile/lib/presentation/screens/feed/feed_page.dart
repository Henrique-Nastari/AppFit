// lib/presentation/screens/feed/feed_page.dart - VERSÃO FINAL

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart'; // Import Vibração

// Imports de Serviços
import '../../../application/auth/auth_service.dart';
import '../../../application/profile/profile_service.dart';
import '../../../application/notifications/notification_service.dart'; // Import Notificação

// Imports de Widgets
import '../../widgets/feed/post_card.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

// Imports das Telas
import '../profile/profile_page.dart';
import '../workouts/workouts_page.dart';
import '../progress/progress_page.dart';
import '../search/search_page.dart';
import '../notifications/notifications_page.dart';
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
    // Define as páginas para a navegação inferior
    _pages = [
      const _FeedContent(),           // Aba 0: Feed Principal
      const WorkoutsPage(),           // Aba 1: Meus Treinos
      const ProgressPage(),           // Aba 2: Meu Desempenho
      const ProfilePage(),            // Aba 3: Meu Perfil
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

// --- CONTEÚDO DO FEED (Aba 0) ---
class _FeedContent extends StatefulWidget {
  const _FeedContent();

  @override
  State<_FeedContent> createState() => _FeedContentState();
}

class _FeedContentState extends State<_FeedContent> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final NotificationService _notificationService = NotificationService();

  int? _previousCount; // Para controlar vibração

  // Dispara vibração e popup local (Heads-up)
  Future<void> _triggerNotificationPopup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Vibra
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }

    // Busca a última notificação para pegar o texto
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final String title = data['senderName'] ?? 'Nova Notificação';
      final String body = data['message'] ?? 'Você tem uma nova interação.';

      // Mostra o Popup
      _notificationService.showLocalNotification(title: title, body: body);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = theme.hintColor;
    final borderColor = theme.dividerColor;
    const primaryColor = Color(0xFF13EC6D); // Verde Neon

    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- CABEÇALHO CUSTOMIZADO ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Lupa (Busca)
                  IconButton(
                    icon: Icon(Icons.search, color: textColor),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SearchPage()),
                      );
                    },
                    tooltip: "Buscar Usuários",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  Text(
                    'AppFit',
                    style: GoogleFonts.epilogue(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: textColor,
                    ),
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- BOTÃO DE NOTIFICAÇÕES (Com Badge e Lógica) ---
                      StreamBuilder<int>(
                        stream: _notificationService.getUnreadCount(),
                        builder: (context, snapshot) {
                          final int count = snapshot.data ?? 0;

                          // Se contador aumentou, notifica
                          if (snapshot.hasData && _previousCount != null && count > _previousCount!) {
                            _triggerNotificationPopup();
                          }
                          if (snapshot.hasData) _previousCount = count;

                          return IconButton(
                            icon: Badge(
                              label: Text('$count', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              isLabelVisible: count > 0,
                              backgroundColor: primaryColor,
                              child: Icon(Icons.notifications_outlined, color: textColor),
                            ),
                            onPressed: () {
                              _notificationService.markAllAsRead();
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const NotificationsPage()),
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          );
                        },
                      ),

                      const SizedBox(width: 16),

                      // Botão Sair
                      IconButton(
                        icon: Icon(Icons.logout, color: subTextColor),
                        onPressed: () {
                          _authService.signOut();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- LISTA DE POSTS (Com Filtro de Seguidores) ---
            Expanded(
              child: StreamBuilder<List<String>>(
                // 1. Ouve quem eu sigo
                stream: currentUser != null
                    ? _profileService.getFollowingIdsStream(currentUser.uid)
                    : Stream.value([]),
                builder: (context, followingSnapshot) {
                  if (followingSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<String> allowedIds = followingSnapshot.data ?? [];
                  if (currentUser != null) {
                    allowedIds.add(currentUser.uid); // Inclui meus posts
                  }

                  // 2. Ouve os posts
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .orderBy('createdAt', descending: true)
                        .limit(100)
                        .snapshots(),
                    builder: (context, postsSnapshot) {
                      if (postsSnapshot.hasError) {
                        return const Center(child: Text('Erro ao carregar posts.'));
                      }
                      if (postsSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // 3. Filtra localmente
                      final allPosts = postsSnapshot.data?.docs ?? [];
                      final filteredPosts = allPosts.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final String postUserId = data['userId'] ?? '';
                        return allowedIds.contains(postUserId);
                      }).toList();

                      if (filteredPosts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.feed_outlined, size: 64, color: subTextColor.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'Seu feed está vazio.',
                                style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Siga pessoas ou crie um post\npara ver conteúdo aqui.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: subTextColor),
                              ),
                              const SizedBox(height: 24),
                              OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const SearchPage()),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textColor,
                                    side: BorderSide(color: subTextColor),
                                  ),
                                  child: const Text("Buscar Amigos")
                              )
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        itemCount: filteredPosts.length,
                        itemBuilder: (context, index) {
                          final postDoc = filteredPosts[index];
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}