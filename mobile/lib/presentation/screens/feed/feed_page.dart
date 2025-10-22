// lib/presentation/screens/feed/feed_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../application/auth/auth_service.dart'; 
import 'create_post_page.dart'; // Import da tela de criação

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 AppFit Feed'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authService.signOut();
              // O AuthGate cuidará do redirecionamento para o login
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // O Stream: Ouve a coleção 'posts', ordenando pelos mais recentes primeiro
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true) // Mais recentes no topo
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Tratamento de Erros e Loading
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar posts.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Verifica se há posts
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum post ainda.\nSeja o primeiro a registrar seu treino!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // 3. Se tudo deu certo, constrói a lista de posts
          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              // Pegamos os dados do documento atual
              final postDoc = posts[index];
              // Convertendo para um mapa para facilitar o acesso
              final postData = postDoc.data() as Map<String, dynamic>; 
              
              // Extraindo os dados que queremos mostrar (com segurança)
              final String caption = postData['caption'] ?? '';
              final String? imageUrl = postData['imageUrl']; // Pode ser nulo
              final String userName = postData['userDisplayName'] ?? 'Usuário Anônimo';
              final Timestamp? timestamp = postData['createdAt']; // Timestamp do Firebase

              // TODO: Criar um widget PostCard mais bonito aqui
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (timestamp != null)
                        Text(
                          // Formatar a data (pode melhorar depois)
                          timestamp.toDate().toString().substring(0, 16), 
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 8),
                      if (imageUrl != null) 
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: 200)
                        ),
                      if (imageUrl != null) const SizedBox(height: 8),
                      Text(caption),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navega para a tela de criação que já temos
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