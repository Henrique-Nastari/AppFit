// lib/presentation/screens/profile/profile_page.dart - CÓDIGO FINAL COMPLETO

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../application/profile/profile_service.dart';
import 'package:intl/intl.dart';
import 'edit_profile_page.dart';
import 'user_list_page.dart';
import '../feed/post_details_page.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  late String _userIdToShow;
  late String _currentUserId;
  late Future<Map<String, dynamic>?> _userDataFuture;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _userPostsStream;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _userIdToShow = widget.userId ?? _currentUserId;

    if (_userIdToShow.isNotEmpty) {
      _loadUserData();
      // Stream principal para a contagem de estatísticas e aba Posts
      _userPostsStream = _profileService.getUserPosts(_userIdToShow);
    } else {
      _userDataFuture = Future.value(null);
      _userPostsStream = Stream.empty();
    }
  }

  void _loadUserData() {
    _userDataFuture = _profileService.getUserData(_userIdToShow);
  }

  Future<void> _toggleFollow(bool isFollowing) async {
    try {
      if (isFollowing) {
        await _profileService.unfollowUser(_userIdToShow);
      } else {
        await _profileService.followUser(_userIdToShow);
      }
      setState(() { _loadUserData(); });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color textColor = theme.colorScheme.onSurface;
    final Color subTextColor = theme.hintColor;
    const Color primaryColor = Color(0xFF13EC6D);
    final Color cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);

    if (_userIdToShow.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(backgroundColor: backgroundColor, elevation: 0),
        body: Center(child: Text("Usuário não encontrado.", style: TextStyle(color: textColor))),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: backgroundColor,
                surfaceTintColor: backgroundColor,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: (widget.userId != null || Navigator.canPop(context))
                    ? IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.of(context).pop(),
                )
                    : null,
                title: _buildUsernameTitle(textColor),
                centerTitle: true,
                actions: [
                  if (_userIdToShow == _currentUserId)
                    IconButton(
                      icon: Icon(Icons.settings, color: textColor),
                      onPressed: () {},
                    ),
                ],
                pinned: true,
                forceElevated: innerBoxIsScrolled,
              ),
              SliverToBoxAdapter(
                child: _buildProfileHeader(textColor, subTextColor, primaryColor, cardColor),
              ),
              SliverToBoxAdapter(
                child: _buildProfileStats(textColor, subTextColor, cardColor),
              ),
              SliverPersistentHeader(
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    labelColor: primaryColor,
                    unselectedLabelColor: subTextColor,
                    indicatorColor: primaryColor,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: GoogleFonts.epilogue(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [
                      Tab(text: "POSTS"),
                      Tab(text: "CONQUISTAS"),
                    ],
                  ),
                  backgroundColor,
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildPostsGrid(textColor),
              _buildAchievementsTab(textColor, subTextColor, primaryColor, cardColor),
            ],
          ),
        ),
      ),
    );
  }

  // --- CONQUISTAS ---

  Widget _buildAchievementsTab(Color textColor, Color subTextColor, Color primaryColor, Color cardColor) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Cria um stream novo para evitar conflitos/loading eterno
      stream: _profileService.getUserPosts(_userIdToShow),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Erro ao carregar conquistas.", style: TextStyle(color: subTextColor)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;
        final achievements = _calculateAchievements(posts);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            final isUnlocked = achievement.isUnlocked;

            return Container(
              decoration: BoxDecoration(
                color: isUnlocked ? cardColor : cardColor.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isUnlocked ? primaryColor.withValues(alpha: 0.3) : Colors.transparent,
                    width: 1
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUnlocked
                          ? primaryColor.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      isUnlocked ? achievement.icon : Icons.lock_outline,
                      color: isUnlocked ? primaryColor : subTextColor.withValues(alpha: 0.3),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    achievement.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.epilogue(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? textColor : subTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      achievement.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: subTextColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Achievement> _calculateAchievements(List<QueryDocumentSnapshot<Map<String, dynamic>>> posts) {
    final int postCount = posts.length;
    double totalVolume = 0;
    int totalDuration = 0;

    for (var doc in posts) {
      final data = doc.data();
      final metrics = data['metrics'] as Map<String, dynamic>?;

      final vol = metrics?['VolumeKg'];
      if (vol is num) totalVolume += vol.toDouble();

      final dur = metrics?['DuracaoMin'];
      if (dur is int) totalDuration += dur;
    }

    return [
      Achievement("Primeiro Passo", "Publique seu 1º treino", Icons.flag, postCount >= 1),
      Achievement("Iniciante", "Publique 5 treinos", Icons.directions_run, postCount >= 5),
      Achievement("Dedicado", "Publique 20 treinos", Icons.fitness_center, postCount >= 20),
      Achievement("Veterano", "Publique 50 treinos", Icons.military_tech, postCount >= 50),
      Achievement("Forte", "Levante 1.000kg totais", Icons.fitness_center, totalVolume >= 1000),
      Achievement("Hulk", "Levante 10.000kg totais", Icons.hardware, totalVolume >= 10000),
      Achievement("Maratonista", "Acumule 5 horas de treino", Icons.timer, totalDuration >= 300),
      Achievement("Lenda", "Acumule 24 horas de treino", Icons.workspace_premium, totalDuration >= 1440),
      Achievement("Influencer", "Ganhe 10 seguidores", Icons.group, false),
    ];
  }

  // --- CABEÇALHO E ESTATÍSTICAS ---

  Widget _buildProfileHeader(Color textColor, Color subTextColor, Color primaryColor, Color cardColor) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
        }
        final userData = snapshot.data ?? {};
        final String displayName = userData['displayName'] ?? 'Usuário';
        final String? photoUrl = userData['photoUrl'];
        final String? bio = userData['bio'];
        final bool isMe = _userIdToShow == _currentUserId;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: cardColor,
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                      child: (photoUrl == null || photoUrl.isEmpty) ? Icon(Icons.person, size: 40, color: subTextColor) : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.epilogue(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bio ?? (isMe ? "Toque em Editar para adicionar uma bio." : ""),
                          style: TextStyle(fontSize: 14, color: subTextColor),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: isMe
                    ? OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const EditProfilePage()),
                    ).then((_) => setState(() { _loadUserData(); }));
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: textColor.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: textColor,
                  ),
                  child: Text("Editar Perfil", style: GoogleFonts.epilogue(fontWeight: FontWeight.bold)),
                )
                    : StreamBuilder<bool>(
                  stream: _profileService.isFollowing(_userIdToShow),
                  builder: (context, followSnapshot) {
                    final bool isFollowing = followSnapshot.data ?? false;
                    return ElevatedButton(
                      onPressed: () => _toggleFollow(isFollowing),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? Colors.transparent : primaryColor,
                        foregroundColor: isFollowing ? textColor : Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isFollowing ? BorderSide(color: textColor.withValues(alpha: 0.2)) : BorderSide.none,
                        ),
                      ),
                      child: Text(
                        isFollowing ? "Seguindo" : "Seguir",
                        style: GoogleFonts.epilogue(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsernameTitle(Color textColor) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        final userData = snapshot.data ?? {};
        final String? username = userData['username'];
        final String emailUsername = (userData['email'] ?? '').split('@').first;
        final String finalUsername = (username != null && username.isNotEmpty) ? username : (emailUsername.isNotEmpty ? emailUsername : 'usuário');
        return Text("@$finalUsername", style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: textColor));
      },
    );
  }

  Widget _buildProfileStats(Color textColor, Color subTextColor, Color cardColor) {
    return FutureBuilder<Map<String, dynamic>?>(
        future: _userDataFuture,
        builder: (context, userSnapshot) {
          final userData = userSnapshot.data;
          final int followers = userData?['followersCount'] ?? 0;
          final int following = userData?['followingCount'] ?? 0;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _userPostsStream,
            builder: (context, snapshot) {
              final int postCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(child: _buildStatItem("Posts", postCount.toString(), textColor, subTextColor, cardColor, null)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatItem("Seguindo", following.toString(), textColor, subTextColor, cardColor, () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserListPage(title: "Seguindo", userId: _userIdToShow, isFollowers: false)));
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatItem("Seguidores", followers.toString(), textColor, subTextColor, cardColor, () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserListPage(title: "Seguidores", userId: _userIdToShow, isFollowers: true)));
                    })),
                  ],
                ),
              );
            },
          );
        }
    );
  }

  Widget _buildStatItem(String label, String value, Color textColor, Color subTextColor, Color cardColor, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
        child: Column(children: [Text(value, style: GoogleFonts.epilogue(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)), const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 12, color: subTextColor))]),
      ),
    );
  }

  Widget _buildPostsGrid(Color textColor) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _userPostsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Erro ao carregar posts.", style: TextStyle(color: textColor)));

        final postsWithImages = snapshot.data?.docs.where((doc) {
          final data = doc.data();
          return data.containsKey('imageUrl') && data['imageUrl'] != null && data['imageUrl'].isNotEmpty;
        }).toList() ?? [];

        if (postsWithImages.isEmpty) return Center(child: Text("Nenhum post com foto.", style: TextStyle(color: textColor)));

        return GridView.builder(
          padding: const EdgeInsets.all(2.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2.0, mainAxisSpacing: 2.0, childAspectRatio: 1.0),
          itemCount: postsWithImages.length,
          itemBuilder: (context, index) {
            final postDoc = postsWithImages[index];
            return GestureDetector(
              onTap: () { Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailsPage(postId: postDoc.id, postData: postDoc.data()))); },
              child: Image.network(postDoc.data()['imageUrl'], fit: BoxFit.cover, loadingBuilder: (c, child, l) => l == null ? child : Container(color: Colors.white.withValues(alpha: 0.05)), errorBuilder: (c, e, s) => Container(color: Colors.white.withValues(alpha: 0.05), child: Icon(Icons.broken_image, color: textColor.withValues(alpha: 0.2)))),
            );
          },
        );
      },
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar, this.backgroundColor);
  final TabBar _tabBar;
  final Color backgroundColor;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) { return Container(color: backgroundColor, child: _tabBar); }
  @override bool shouldRebuild(_SliverTabBarDelegate oldDelegate) { return false; }
}

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  Achievement(this.title, this.description, this.icon, this.isUnlocked);
}