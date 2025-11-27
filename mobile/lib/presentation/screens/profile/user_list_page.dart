// lib/presentation/screens/profile/user_list_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../application/profile/profile_service.dart';
import 'profile_page.dart'; // Para navegar ao perfil da pessoa

class UserListPage extends StatelessWidget {
  final String title;
  final String userId;
  final bool isFollowers; // true = seguidores, false = seguindo

  const UserListPage({
    super.key,
    required this.title,
    required this.userId,
    required this.isFollowers,
  });

  @override
  Widget build(BuildContext context) {
    final ProfileService _profileService = ProfileService();
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.epilogue(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // 1. Primeiro Stream: Pega a lista de IDs
      body: StreamBuilder<List<String>>(
        stream: isFollowers
            ? _profileService.getFollowersIdsStream(userId)
            : _profileService.getFollowingIdsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<String> userIds = snapshot.data ?? [];

          if (userIds.isEmpty) {
            return Center(child: Text("Nenhum usuário encontrado.", style: TextStyle(color: theme.hintColor)));
          }

          // 2. Lista de Usuários: Busca os dados de cada ID
          return ListView.builder(
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              final String id = userIds[index];

              // FutureBuilder para buscar dados (nome, foto) de CADA usuário
              return FutureBuilder<Map<String, dynamic>?>(
                future: _profileService.getUserData(id),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    // Placeholder enquanto carrega
                    return const ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.grey),
                      title: Text("Carregando..."),
                    );
                  }

                  final userData = userSnapshot.data!;
                  final String name = userData['displayName'] ?? 'Usuário';
                  final String? photoUrl = userData['photoUrl'];
                  final String username = userData['username'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: username.isNotEmpty ? Text("@$username", style: TextStyle(color: theme.hintColor)) : null,
                    onTap: () {
                      // Navega para o perfil da pessoa
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(userId: id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}