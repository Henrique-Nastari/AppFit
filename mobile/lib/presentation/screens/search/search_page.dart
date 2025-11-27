// lib/presentation/screens/search/search_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../application/profile/profile_service.dart';
import '../profile/profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ProfileService _profileService = ProfileService();
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isLoading = false;

  void _onSearch() async {
    setState(() => _isLoading = true);
    try {
      final results = await _profileService.searchUsers(_searchController.text.trim());
      setState(() {
        _searchResults = results;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;
    final inputFill = isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text("Explorar", style: GoogleFonts.epilogue(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Buscar usuários...",
                hintStyle: TextStyle(color: theme.hintColor),
                filled: true,
                fillColor: inputFill,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Color(0xFF13EC6D)),
                  onPressed: _onSearch,
                ),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),

          // Lista de Resultados
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(child: Text("Pesquise por um nome", style: TextStyle(color: theme.hintColor)))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final userDoc = _searchResults[index];
                final userData = userDoc.data() as Map<String, dynamic>;
                final userId = userDoc.id;
                final photoUrl = userData['photoUrl'];
                final name = userData['displayName'] ?? 'Usuário';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text("@${userData['username'] ?? ''}", style: TextStyle(color: theme.hintColor)),
                  onTap: () {
                    // Navegar para o perfil desse usuário
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(userId: userId),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}