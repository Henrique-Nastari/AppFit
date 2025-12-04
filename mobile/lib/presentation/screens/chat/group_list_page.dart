import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../application/chat/chat_service.dart';
import '../../../models/chat_group.dart';
import 'group_chat_page.dart';
import 'group_new_page.dart';

class GroupListPage extends StatelessWidget {
  GroupListPage({super.key});

  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos'),
      ),
      body: StreamBuilder<List<ChatGroup>>(
        stream: _chatService.streamMyGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar grupos: ${snapshot.error}'));
          }

          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return const _EmptyGroups();
          }

          return ListView.separated(
            itemCount: groups.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final group = groups[index];
              final members = group.memberIds.length;
              return ListTile(
                title: Text(group.name),
                subtitle: Text('$members participante${members == 1 ? '' : 's'}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GroupChatPage(group: group),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final groupId = await Navigator.of(context).push<String>(
            MaterialPageRoute(builder: (_) => const GroupNewPage()),
          );

          if (groupId != null && context.mounted) {
            final allGroups = await _chatService.streamMyGroups().first;
            final group = allGroups.firstWhere(
              (g) => g.id == groupId,
              orElse: () => groupsPlaceholder(groupId),
            );
            if (!context.mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupChatPage(group: group),
              ),
            );
          }
        },
        icon: const Icon(Icons.group_add),
        label: const Text('Criar grupo'),
      ),
    );
  }

  ChatGroup groupsPlaceholder(String id) {
    final user = FirebaseAuth.instance.currentUser;
    return ChatGroup(
      id: id,
      name: 'Grupo',
      ownerId: user?.uid ?? '',
      memberIds: [if (user != null) user.uid],
      createdAt: DateTime.now(),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              'Nenhum grupo ainda',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie um grupo com seus amigos para compartilhar treinos e conversar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
