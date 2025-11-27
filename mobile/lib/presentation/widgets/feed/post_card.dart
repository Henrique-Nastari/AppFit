// lib/presentation/widgets/feed/post_card.dart - COM COMPARTILHAMENTO

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart'; // <-- 1. IMPORT ADICIONADO
import '../../../application/feed/reaction_service.dart';
import 'comments/comments_sheet.dart';

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

  // Cores do Design
  final Color _cardBackgroundColor = Colors.black.withValues(alpha: 0.4);
  final Color _primaryColor = const Color(0xFF13EC6D);
  final Color _textColor = Colors.white;
  final Color _subTextColor = Colors.white.withValues(alpha: 0.6);

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(postId: widget.postId),
    );
  }

  // --- 2. NOVO MÉTODO DE COMPARTILHAR ---
  void _sharePost() {
    final String userName = widget.postData['userDisplayName'] ?? 'Atleta';
    final String? workoutTitle = widget.postData['workoutTitle'];
    final String? caption = widget.postData['caption'];

    // Monta o texto do compartilhamento
    final StringBuffer shareText = StringBuffer();
    shareText.writeln('🔥 Confira o treino de $userName no AppFit!');

    if (workoutTitle != null && workoutTitle.isNotEmpty) {
      shareText.writeln('\nTreino: $workoutTitle');
    }

    if (caption != null && caption.isNotEmpty) {
      shareText.writeln('"$caption"');
    }

    shareText.writeln('\n#AppFit #Fitness #Treino');

    // Abre a janela nativa de compartilhamento
    Share.share(shareText.toString());
  }
  // --------------------------------------

  @override
  Widget build(BuildContext context) {
    final String userName = widget.postData['userDisplayName'] ?? 'Atleta';
    final String? userPhotoUrl = widget.postData['userPhotoUrl'];
    final String? caption = widget.postData['caption'];
    final String? imageUrl = widget.postData['imageUrl'];
    final Timestamp? createdAt = widget.postData['createdAt'];
    final String? workoutTitle = widget.postData['workoutTitle'];
    final List<dynamic>? exercises = widget.postData['exercises'] as List<dynamic>?;
    final Map<String, dynamic>? metrics = widget.postData['metrics'] as Map<String, dynamic>?;

    final int commentCount = widget.postData['commentCount'] ?? 0;

    String timeAgo = '';
    if (createdAt != null) {
      timeAgo = _formatTimeAgo(createdAt.toDate());
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade800,
                  backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                      ? NetworkImage(userPhotoUrl)
                      : null,
                  child: userPhotoUrl == null || userPhotoUrl.isEmpty
                      ? Icon(Icons.person, color: _subTextColor, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.epilogue(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      if (timeAgo.isNotEmpty)
                        Text(
                          timeAgo,
                          style: GoogleFonts.epilogue(
                            fontSize: 12,
                            color: _subTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: _subTextColor),
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // TEXTOS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (workoutTitle != null && workoutTitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      workoutTitle,
                      style: GoogleFonts.epilogue(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                  ),
                if (caption != null && caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      caption,
                      style: GoogleFonts.epilogue(
                        fontSize: 15,
                        color: _textColor.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // DETALHES DO TREINO
          if (exercises != null && exercises.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWorkoutDetails(context, exercises),
                  if (metrics != null && metrics.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildMetricsChips(context, metrics),
                  ]
                ],
              ),
            ),

          // IMAGEM
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(height: 250, color: Colors.white10, child: const Center(child: CircularProgressIndicator()));
              },
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 200, color: Colors.white10, child: Center(child: Icon(Icons.broken_image, color: _subTextColor))),
            ),

          // RODAPÉ (Reações e Ações)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: _buildReactionsRow(commentCount),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsRow(int commentCount) {
    if (_userId == null) {
      return Text("Faça login para reagir.", style: TextStyle(color: _subTextColor, fontSize: 12));
    }

    return StreamBuilder<String?>(
      stream: _reactionService.watchUserReaction(postId: widget.postId, userId: _userId!),
      builder: (context, userReactionSnapshot) {
        final String? currentUserEmoji = userReactionSnapshot.data;

        return StreamBuilder<Map<String, int>>(
          stream: _reactionService.watchReactionCounts(postId: widget.postId),
          builder: (context, countsSnapshot) {
            final Map<String, int> reactionCounts = countsSnapshot.data ?? {};
            final visibleReactions = reactionCounts.entries
                .where((entry) => entry.value > 0)
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Botões de Reação
                ...visibleReactions.map((entry) {
                  bool isMine = currentUserEmoji == entry.key;
                  return GestureDetector(
                    onTap: () => _toggleReaction(entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isMine ? _primaryColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isMine ? _primaryColor : Colors.transparent,
                            width: 1
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(entry.key, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '${entry.value}',
                            style: GoogleFonts.epilogue(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isMine ? _primaryColor : _subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                // Botão Reagir (+)
                IconButton(
                  icon: Icon(
                      currentUserEmoji != null ? Icons.add_reaction : Icons.add_reaction_outlined,
                      color: _subTextColor
                  ),
                  onPressed: _showReactionPicker,
                  tooltip: "Reagir",
                ),

                // Botão Comentar
                TextButton.icon(
                  onPressed: _showComments,
                  icon: Icon(Icons.chat_bubble_outline, color: _subTextColor),
                  label: Text(
                    commentCount > 0 ? '$commentCount' : '',
                    style: GoogleFonts.epilogue(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _subTextColor
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                // --- 3. BOTÃO DE COMPARTILHAR CONECTADO ---
                IconButton(
                  icon: Icon(Icons.share_outlined, color: _subTextColor),
                  onPressed: _sharePost, // Chama o método _sharePost
                  tooltip: "Compartilhar",
                ),
                // ------------------------------------------
              ],
            );
          },
        );
      },
    );
  }

  void _showReactionPicker() {
    if (_userId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF102218),
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

  Widget _buildWorkoutDetails(BuildContext context, List<dynamic>? exercises) {
    if (exercises == null || exercises.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: exercises.map<Widget>((exerciseData) {
        if (exerciseData is! Map) return const SizedBox.shrink();
        final Map<String, dynamic> exerciseMap = Map<String, dynamic>.from(exerciseData);
        final String exerciseName = exerciseMap['name'] ?? 'Exercício';
        final List<dynamic>? sets = exerciseMap['sets'] as List<dynamic>?;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fitness_center, size: 14, color: _primaryColor),
                  const SizedBox(width: 6),
                  Text(
                      exerciseName,
                      style: GoogleFonts.epilogue(
                          color: _textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14
                      )
                  ),
                ],
              ),
              if (sets != null && sets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sets.asMap().entries.map<Widget>((entry) {
                      int setIndex = entry.key;
                      if (entry.value is! Map) return const SizedBox.shrink();
                      Map<String, dynamic> setData = Map<String, dynamic>.from(entry.value);
                      List<String> details = [];
                      if (setData['reps'] != null) details.add('${setData['reps']} reps');
                      if (setData['weight'] != null) details.add('${setData['weight']}kg');
                      if (details.isNotEmpty) {
                        return Text(
                          '${setIndex + 1}: ${details.join(' • ')}',
                          style: GoogleFonts.epilogue(color: _subTextColor, fontSize: 12),
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
    );
  }

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

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            '$label: $displayValue$unit',
            style: GoogleFonts.epilogue(fontSize: 11, color: _subTextColor),
          ),
        );
      }).toList(),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    if (diff.inDays < 7) return '${diff.inDays}d atrás';
    try { return DateFormat('dd MMM', 'pt_BR').format(dt); }
    catch (e) { return DateFormat('yyyy-MM-dd').format(dt); }
  }
}