// lib/presentation/widgets/feed/post_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar datas
import '../../../application/feed/reaction_service.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostCard({super.key, required this.postId, required this.postData});

  @override
  Widget build(BuildContext context) {
    // Extraindo dados do post com segurança
    final String userName = postData['userDisplayName'] ?? 'Atleta';
    final String? userPhotoUrl = postData['userPhotoUrl'];
    final String? workoutTitle = postData['workoutTitle'];
    final String? caption = postData['caption'];
    final String? imageUrl = postData['imageUrl'];
    final Timestamp? createdAt = postData['createdAt'];
    final List<dynamic>? exercises =
        postData['exercises'] as List<dynamic>?; // Lista de exercícios
    final Map<String, dynamic>? metrics =
        postData['metrics'] as Map<String, dynamic>?; // Métricas adicionais

    String formattedDate = '';
    if (createdAt != null) {
      try {
        formattedDate = DateFormat(
                "dd 'de' MMMM 'de' yyyy 'às' HH:mm", 'pt_BR')
            .format(createdAt.toDate());
      } catch (e) {
        // Fallback caso a formatação de locale falhe
        formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate());
      }
    }

    return Card(
      margin:
          const EdgeInsets.symmetric(vertical: 8, horizontal: 0), // Full width
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER DO POST: Nome do Usuário e Data ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                      ? NetworkImage(userPhotoUrl)
                      : null,
                  child: userPhotoUrl == null || userPhotoUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 24)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (formattedDate.isNotEmpty)
                        Text(
                          formattedDate,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- IMAGEM DO TREINO ---
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300, // Altura fixa para as imagens
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                ),
              ),
            ),

          // --- DETALHES DO TREINO (Título, Exercícios, Métricas) ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (workoutTitle != null && workoutTitle.isNotEmpty)
                  Text(
                    workoutTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),

                if (exercises != null && exercises.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Exercícios',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  ...exercises.map((ex) {
                    if (ex is! Map) return const SizedBox.shrink();
                    final exMap = Map<String, dynamic>.from(ex);
                    final exerciseName = (exMap['name'] as String?) ?? '-';
                    final exerciseNotes = exMap['notes'] as String?;
                    final sets = exMap['sets'] as List?;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exerciseName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (exerciseNotes != null &&
                              exerciseNotes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                exerciseNotes,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[700]),
                              ),
                            ),
                          if (sets != null && sets.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    sets.asMap().entries.map((entry) {
                                  int setIndex = entry.key;
                                  if (entry.value is! Map) {
                                    return const SizedBox.shrink();
                                  }
                                  final setData = Map<String, dynamic>.from(
                                      entry.value as Map);

                                  // Construindo a string de detalhes
                                  final details = <String>[];
                                  if (setData['reps'] != null) {
                                    details.add("${setData['reps']} reps");
                                  }
                                  if (setData['weight'] != null) {
                                    details.add("${setData['weight']} kg");
                                  }
                                  if (setData['distance'] != null) {
                                    details.add("${setData['distance']} m");
                                  }
                                  if (setData['duration'] != null) {
                                    details.add("${setData['duration']} seg");
                                  }
                                  if (setData['rpe'] != null) {
                                    details.add("RPE ${setData['rpe']}");
                                  }

                                  if (details.isNotEmpty) {
                                    return Text(
                                      "${setIndex + 1}: ${details.join(' | ')}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],

                // --- Métricas Adicionais ---
                if (metrics != null && metrics.isNotEmpty) ...[
                  if (exercises != null && exercises.isNotEmpty)
                    const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: metrics.entries.map((entry) {
                      String label = entry.key;
                      final value = entry.value;
                      final displayValue = value.toString();
                      String unit = '';

                      if (label == 'DuracaoMin') {
                        label = 'Duração';
                        unit = ' min';
                      }
                      if (label == 'VolumeKg') {
                        label = 'Volume';
                        unit = ' kg';
                      }
                      if (label == 'Calorias') {
                        unit = ' kcal';
                      }

                      return Chip(
                        label: Text('$label: $displayValue$unit',
                            style: const TextStyle(fontSize: 12)),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 0),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.5),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // --- LEGENDA (Caption) ---
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                  left: 12.0, right: 12.0, bottom: 12.0, top: 4.0),
              child: Text(
                caption,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),

          // --- REAÇÕES (Emojis) ---
          _ReactionsSection(postId: postId),
        ],
      ),
    );
  }
}

class _ReactionsSection extends StatelessWidget {
  const _ReactionsSection({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    final service = ReactionService();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<Map<String, int>>(
            stream: service.watchReactionCounts(postId: postId),
            builder: (context, snapshot) {
              final counts = snapshot.data ?? const <String, int>{};
              final entries = counts.entries
                  .where((e) => (e.value) > 0)
                  .toList()
                ..sort((a, b) {
                  final c = b.value.compareTo(a.value);
                  return c != 0 ? c : a.key.compareTo(b.key);
                });

              if (entries.isEmpty) {
                return Row(
                  children: [
                    _AddReactionButton(postId: postId),
                  ],
                );
              }

              return Row(
                children: [
                  Flexible(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: entries.map((e) {
                        return _ReactionChip(
                          postId: postId,
                          emoji: e.key,
                          count: e.value,
                          highlightStream: userId == null
                              ? const Stream<String?>.empty()
                              : ReactionService().watchUserReaction(
                                  postId: postId, userId: userId),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AddReactionButton(postId: postId),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.postId,
    required this.emoji,
    required this.count,
    required this.highlightStream,
  });

  final String postId;
  final String emoji;
  final int count;
  final Stream<String?> highlightStream;

  @override
  Widget build(BuildContext context) {
    final service = ReactionService();

    return StreamBuilder<String?>(
      stream: highlightStream,
      builder: (context, snapshot) {
        final mine = snapshot.data == emoji;
        final bg = mine
            ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
            : Theme.of(context)
                .colorScheme
                .surfaceVariant
                .withOpacity(0.6);
        final border =
            mine ? Theme.of(context).colorScheme.primary : Colors.transparent;

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () async {
            try {
              await service.toggleReaction(postId: postId, emoji: emoji);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Falha ao reagir: $e')),
              );
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddReactionButton extends StatelessWidget {
  const _AddReactionButton({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.emoji_emotions_outlined, size: 18),
      label: const Text('Reagir'),
      onPressed: () async {
        await showModalBottomSheet(
          context: context,
          builder: (context) => _EmojiPickerSheet(postId: postId),
        );
      },
    );
  }
}

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final emojis = ReactionService.defaultEmojis;
    final service = ReactionService();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final e in emojis)
              GestureDetector(
                onTap: () async {
                  try {
                    await service.toggleReaction(postId: postId, emoji: e);
                    // Fecha após selecionar
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  } catch (err) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Falha ao reagir: $err')),
                    );
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
