// lib/presentation/widgets/feed/post_card.dart - CORREÇÃO FINAL (Null Safety)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../application/feed/reaction_service.dart'; // Import do ReactionService

class PostCard extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostCard({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final ReactionService _reactionService = ReactionService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    // Extraindo dados
    final String userName = widget.postData['userDisplayName'] ?? 'Atleta';
    final String? userPhotoUrl = widget.postData['userPhotoUrl'];
    final String? caption = widget.postData['caption'];
    final String? imageUrl = widget.postData['imageUrl'];
    final Timestamp? createdAt = widget.postData['createdAt'];
    final String? workoutTitle = widget.postData['workoutTitle'];
    final List<dynamic>? exercises = widget.postData['exercises'] as List<dynamic>?;
    final Map<String, dynamic>? metrics = widget.postData['metrics'] as Map<String, dynamic>?;

    String timeAgo = '';
    if (createdAt != null) {
      timeAgo = _formatTimeAgo(createdAt.toDate());
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: Avatar, Nome, Data ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                        ? NetworkImage(userPhotoUrl)
                        : null,
                    child: userPhotoUrl == null || userPhotoUrl.isEmpty
                        ? Icon(Icons.person, color: Colors.grey[600], size: 24)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (timeAgo.isNotEmpty)
                          Text(
                            timeAgo,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // --- IMAGEM DO POST ---
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0, bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container( height: 250, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container( height: 250, color: Colors.grey[200], child: Center(child: Icon(Icons.broken_image, color: Colors.grey[600])));
                    },
                  ),
                ),
              ),

            // --- Conteúdo Principal (Título, Exercícios, Legenda, Métricas) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (workoutTitle != null && workoutTitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        workoutTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (exercises != null && exercises.isNotEmpty)
                    _buildWorkoutDetails(context, exercises),
                  if (metrics != null && metrics.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildMetricsChips(context, metrics),
                  ],
                  if ((workoutTitle != null && workoutTitle.isNotEmpty) || (exercises != null && exercises.isNotEmpty) || (metrics != null && metrics.isNotEmpty) )
                    const SizedBox(height: 8),
                  if (caption != null && caption.isNotEmpty)
                    Text(caption, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // --- SEÇÃO DE REAÇÕES ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: _buildReactionsRow(),
            ),
            const SizedBox(height: 12), // Espaço final
          ],
        ),
      ),
    );
  }

  /// Widget helper para a linha de reações
  Widget _buildReactionsRow() {
    return StreamBuilder<String?>(
      stream: _userId != null
          ? _reactionService.watchUserReaction(postId: widget.postId, userId: _userId!)
          : Stream.value(null),
      builder: (context, userReactionSnapshot) {
        if (userReactionSnapshot.hasError) {
          return Tooltip(message: userReactionSnapshot.error.toString(), child: Text("Erro", style: TextStyle(color: Colors.red.shade300, fontSize: 12)));
        }
        final String? currentUserEmoji = userReactionSnapshot.data;

        return StreamBuilder<Map<String, int>>(
          stream: _reactionService.watchReactionCounts(postId: widget.postId),
          builder: (context, countsSnapshot) {
            if (countsSnapshot.hasError) {
              return Tooltip(message: countsSnapshot.error.toString(), child: Text("Erro contagem", style: TextStyle(color: Colors.red.shade300, fontSize: 12)));
            }
            if (countsSnapshot.connectionState == ConnectionState.waiting && !countsSnapshot.hasData && !userReactionSnapshot.hasData) {
              return const SizedBox(height: 30, child: Center(child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))));
            }

            final Map<String, int> reactionCounts = countsSnapshot.data ?? {};
            final visibleReactions = reactionCounts.entries
                .where((entry) => entry.value > 0)
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Row(
              children: [
                // Mostra as reações com contagem
                ...visibleReactions.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: () => _toggleReaction(entry.key),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: currentUserEmoji == entry.key
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).chipTheme.backgroundColor ?? Colors.grey.shade200,
                        foregroundColor: currentUserEmoji == entry.key
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        shape: const StadiumBorder(),
                        elevation: 0,
                        side: BorderSide.none,
                      ),
                      child: Text(
                        '${entry.key} ${entry.value}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                }).toList(),

                // Botão "Reagir"
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_reaction_outlined, size: 18),
                  label: Text(currentUserEmoji != null ? 'Reagiu' : 'Reagir'),
                  onPressed: _showReactionPicker,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const StadiumBorder(),
                      side: BorderSide(color: Colors.grey.shade400)
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Mostra um ModalBottomSheet para escolher um emoji
  void _showReactionPicker() {
    if (_userId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10.0,
              runSpacing: 5.0,
              children: ReactionService.defaultEmojis.map((emoji) {
                return TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _toggleReaction(emoji);
                  },
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(40, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// Função auxiliar para chamar o toggleReaction
  Future<void> _toggleReaction(String emoji) async {
    if (_userId == null) return;
    try {
      await _reactionService.toggleReaction(
        postId: widget.postId,
        emoji: emoji,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao reagir: ${e.toString()}'))
        );
      }
    }
  }

  /// Widget helper para construir os detalhes do treino (CORRIGIDO Null Safety)
  Widget _buildWorkoutDetails(BuildContext context, List<dynamic>? exercises) {
    if (exercises == null || exercises.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // CORREÇÃO: Adicionado tipo explícito <Widget> ao map
      children: exercises.map<Widget>((exerciseData) {
        if (exerciseData is! Map) return const SizedBox.shrink();
        final Map<String, dynamic> exerciseMap = Map<String, dynamic>.from(exerciseData);
        final String exerciseName = exerciseMap['name'] ?? 'Exercício';
        final List<dynamic>? sets = exerciseMap['sets'] as List<dynamic>?;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0, top: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  exerciseName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)
              ),
              if (sets != null && sets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // CORREÇÃO: Adicionado tipo explícito <Widget> ao map
                    children: sets.asMap().entries.map<Widget>((entry) {
                      int setIndex = entry.key;
                      if (entry.value is! Map) return const SizedBox.shrink();
                      Map<String, dynamic> setData = Map<String, dynamic>.from(entry.value);
                      List<String> details = [];
                      if (setData['reps'] != null) details.add('${setData['reps']}x');
                      if (setData['weight'] != null) details.add('${setData['weight']}kg');

                      if (details.isNotEmpty) {
                        return Text(
                          '${setIndex + 1}: ${details.join(' ')}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                        );
                      }
                      // Garante que sempre retorna um Widget
                      return const SizedBox.shrink();
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
        // CORREÇÃO: Adicionado fallback explícito (embora map não deva retornar null aqui)
        // return const SizedBox.shrink(); // Não é necessário aqui, pois o map itera sobre a lista
      }).toList(),
    );
  }

  /// Widget Helper para exibir as métricas como Chips
  Widget _buildMetricsChips(BuildContext context, Map<String, dynamic> metrics) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: metrics.entries.map((entry) {
        String label = entry.key;
        dynamic value = entry.value;
        String displayValue = value.toString();
        String unit = '';
        if (label == 'DuracaoMin') { label = 'Duração'; unit = ' min'; }
        if (label == 'VolumeKg') { label = 'Volume'; unit = ' kg'; }
        if (label == 'Calorias') { unit = ' kcal'; }
        return Chip(
          label: Text('$label: $displayValue$unit', style: TextStyle(fontSize: 12)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          visualDensity: VisualDensity.compact,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }


  /// Helper para formatar o tempo relativo (CORRIGIDO Null Safety)
  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays < 7) return 'há ${diff.inDays} d';

    try {
      return DateFormat('dd MMM', 'pt_BR').format(dt);
    } catch (e) {
      // print("Locale pt_BR não encontrado para DateFormat, usando formato padrão.");
      return DateFormat('yyyy-MM-dd').format(dt); // Fallback
    }
    // CORREÇÃO: Adicionando retorno final explícito para satisfazer o analisador
    // Embora inalcançável devido ao try/catch cobrir o caso 'else'.
    // return DateFormat('yyyy-MM-dd').format(dt);
  }
}