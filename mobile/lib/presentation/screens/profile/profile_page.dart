// lib/presentation/screens/profile/profile_page.dart - FINAL (Sem Botão Voltar)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../application/profile/profile_service.dart';
import 'package:intl/intl.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  late String _userIdToShow;
  late Future<Map<String, dynamic>?> _userDataFuture;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _userPostsStream;

  @override
  void initState() {
    super.initState();
    _userIdToShow = widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    if (_userIdToShow.isNotEmpty) {
      _loadUserData();
      _userPostsStream = _profileService.getUserPosts(_userIdToShow);
    } else {
      _userDataFuture = Future.value(null);
      _userPostsStream = Stream.empty();
    }
  }

  void _loadUserData() {
    _userDataFuture = _profileService.getUserData(_userIdToShow);
  }

  @override
  Widget build(BuildContext context) {
    if (_userIdToShow.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Usuário não encontrado ou não logado.")),
      );
    }

    return DefaultTabController(
      length: 2, // Posts e Conquistas
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                // --- CORREÇÃO: Botão 'leading' (voltar) REMOVIDO daqui ---
                // Isso impede que o usuário tente "fechar" a aba principal
                automaticallyImplyLeading: false, // Garante que não apareça seta automática

                title: _buildUsernameTitle(),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {},
                  ),
                ],
                pinned: true,
                forceElevated: innerBoxIsScrolled,
              ),
              SliverToBoxAdapter(
                child: _buildProfileHeader(),
              ),
              SliverToBoxAdapter(
                child: _buildProfileStats(),
              ),
              SliverPersistentHeader(
                delegate: _SliverTabBarDelegate(
                  const TabBar(
                    tabs: [
                      Tab(text: "POSTS"),
                      Tab(text: "CONQUISTAS"),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              // Aba 1: Posts (A grade)
              _buildPostsGrid(),

              // Aba 2: Conquistas
              const Center(child: Text("Conquistas (Em breve)")),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o cabeçalho do perfil
  Widget _buildProfileHeader() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("Erro ao carregar perfil."));
        }

        final userData = snapshot.data!;
        final String displayName = userData['displayName'] ?? 'Sem Nome';
        final String? photoUrl = userData['photoUrl'];
        final String? bio = userData['bio'];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                    child: (photoUrl == null || photoUrl.isEmpty) ? Icon(Icons.person, size: 48, color: Colors.grey[600]) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.epilogue(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bio ?? "Edite seu perfil para adicionar uma bio.",
                          style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    ).then((_) {
                      setState(() {
                        _loadUserData();
                      });
                    });
                  },
                  child: Text("Editar Perfil", style: GoogleFonts.epilogue(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Constrói o Título (username)
  Widget _buildUsernameTitle() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final userData = snapshot.data!;
        final String? username = userData['username'];
        final String emailUsername = (userData['email'] ?? '').split('@').first;
        final String finalUsername = (username != null && username.isNotEmpty)
            ? username
            : (emailUsername.isNotEmpty ? emailUsername : 'usuário');
        return Text("@$finalUsername");
      },
    );
  }

  /// Constrói as estatísticas
  Widget _buildProfileStats() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _userPostsStream,
      builder: (context, snapshot) {
        final int postCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        final int followingCount = 0;
        final int followersCount = 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(child: _buildStatItem("Posts", postCount.toString())),
              const SizedBox(width: 12),
              Expanded(child: _buildStatItem("Seguindo", followingCount.toString())),
              const SizedBox(width: 12),
              Expanded(child: _buildStatItem("Seguidores", followersCount.toString())),
            ],
          ),
        );
      },
    );
  }

  /// Widget helper para um item de estatística
  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.epilogue(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  /// CONSTRUÇÃO DA GRADE DE POSTS (Aba 1)
  Widget _buildPostsGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _userPostsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Erro ao carregar posts."));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Nenhum post encontrado."));
        }

        final postsWithImages = snapshot.data!.docs
            .where((doc) {
          final data = doc.data();
          return data.containsKey('imageUrl') &&
              data['imageUrl'] != null &&
              data['imageUrl'].isNotEmpty;
        }).toList();

        if (postsWithImages.isEmpty) {
          return const Center(child: Text("Nenhum post com foto encontrado."));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2.0,
            mainAxisSpacing: 2.0,
            childAspectRatio: 1.0,
          ),
          itemCount: postsWithImages.length,
          itemBuilder: (context, index) {
            final postData = postsWithImages[index].data();
            final String imageUrl = postData['imageUrl'];

            return GestureDetector(
              onTap: () { /* TODO: Navegar para detalhes do post */ },
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(color: Colors.grey[200]);
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey[100], child: Icon(Icons.broken_image, color: Colors.grey[300]));
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// Classe helper para fazer a TabBar ficar "grudenta"
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}