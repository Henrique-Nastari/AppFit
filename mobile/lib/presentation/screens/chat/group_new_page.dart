import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../application/chat/chat_service.dart';

class GroupNewPage extends StatefulWidget {
  const GroupNewPage({super.key});

  @override
  State<GroupNewPage> createState() => _GroupNewPageState();
}

class _GroupNewPageState extends State<GroupNewPage> {
  final _nameController = TextEditingController();
  final ChatService _chatService = ChatService();
  bool _loading = true;
  bool _saving = false;
  List<_SelectableUser> _friends = [];

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final followingSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .get();

      final ids = followingSnap.docs.map((d) => d.id).toList();
      if (ids.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final List<_SelectableUser> fetched = [];
      const chunkSize = 10; // limite do whereIn
      for (var i = 0; i < ids.length; i += chunkSize) {
        final chunk = ids.sublist(i, i + chunkSize > ids.length ? ids.length : i + chunkSize);
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        fetched.addAll(usersSnap.docs.map((doc) {
          final data = doc.data();
          return _SelectableUser(
            id: doc.id,
            name: data['displayName'] as String? ?? 'Amigo',
            photoUrl: data['photoUrl'] as String?,
          );
        }));
      }

      setState(() {
        _friends = fetched;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar amigos: $e')),
      );
    }
  }

  Future<void> _createGroup() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Defina um nome para o grupo.')),
      );
      return;
    }

    final selectedIds = _friends.where((f) => f.selected).map((f) => f.id).toList();
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um amigo.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final groupId = await _chatService.createGroup(name: name, memberIds: selectedIds);
      if (!mounted) return;
      Navigator.of(context).pop(groupId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar grupo: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo grupo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do grupo',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Text(
                'Amigos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _friends.isEmpty
                        ? const Center(
                            child: Text('Nenhum amigo seguido ainda.'),
                          )
                        : ListView.builder(
                            itemCount: _friends.length,
                            itemBuilder: (context, index) {
                              final friend = _friends[index];
                              return CheckboxListTile(
                                value: friend.selected,
                                onChanged: (value) {
                                  setState(() {
                                    friend.selected = value ?? false;
                                  });
                                },
                                title: Text(friend.name),
                                secondary: friend.photoUrl != null
                                    ? CircleAvatar(backgroundImage: NetworkImage(friend.photoUrl!))
                                    : const CircleAvatar(child: Icon(Icons.person)),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _createGroup,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Criar grupo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableUser {
  final String id;
  final String name;
  final String? photoUrl;
  bool selected;

  _SelectableUser({
    required this.id,
    required this.name,
    this.photoUrl,
    this.selected = false,
  });
}
