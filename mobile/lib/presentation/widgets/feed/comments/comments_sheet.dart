// lib/presentation/widgets/feed/comments/comments_sheet.dart - COMPLETO (Likes + Respostas)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../application/feed/comment_service.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;

  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Estado para controlar se estamos respondendo a alguém
  String? _replyingToCommentId;
  String? _replyingToUserName;
  final FocusNode _focusNode = FocusNode(); // Para focar no input

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePost() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      if (_replyingToCommentId != null) {
        // Enviar RESPOSTA
        await _commentService.addReply(
          postId: widget.postId,
          commentId: _replyingToCommentId!,
          content: text,
        );
      } else {
        // Enviar COMENTÁRIO normal
        await _commentService.addComment(
          postId: widget.postId,
          content: text,
        );
      }
      _commentController.clear();
      _cancelReply(); // Sai do modo resposta
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  void _startReply(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
    // Foca no campo de texto automaticamente
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF102218) : const Color(0xFFF6F8F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    const primaryColor = Color(0xFF13EC6D);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // --- HEADER ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text("Comentários", style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          ),
          Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),

          // --- LISTA ---
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _commentService.getComments(widget.postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data!.docs;
                if (comments.isEmpty) return Center(child: Text('Seja o primeiro a comentar!', style: TextStyle(color: subTextColor)));

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120), // Espaço para o input + aviso de resposta
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final doc = comments[index];
                    final data = doc.data();
                    return _buildCommentTile(doc.id, data, textColor, subTextColor, primaryColor);
                  },
                );
              },
            ),
          ),

          // --- RODAPÉ (INPUT) ---
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12 + MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
              color: backgroundColor.withValues(alpha: 0.95),
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Aviso "Respondendo a..."
                if (_replyingToUserName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                    child: Row(
                      children: [
                        Text("Respondendo a ", style: TextStyle(color: subTextColor, fontSize: 12)),
                        Text(_replyingToUserName!, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        const Spacer(),
                        GestureDetector(
                          onTap: _cancelReply,
                          child: Icon(Icons.close, size: 16, color: subTextColor),
                        )
                      ],
                    ),
                  ),

                // Campo de texto
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[300],
                      // TODO: Foto do usuário logado
                      child: Icon(Icons.person, size: 24, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                focusNode: _focusNode,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  hintText: _replyingToUserName != null ? "Sua resposta..." : "Adicione um comentário...",
                                  hintStyle: TextStyle(color: subTextColor),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  isDense: true,
                                ),
                                maxLines: null,
                              ),
                            ),
                            IconButton(
                              onPressed: _handlePost,
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                                child: const Icon(Icons.send, size: 18, color: Colors.black),
                              ),
                              padding: const EdgeInsets.only(right: 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(String commentId, Map<String, dynamic> data, Color textColor, Color? subTextColor, Color primaryColor) {
    final String userName = data['userName'] ?? 'Usuário';
    final String? userPhotoUrl = data['userPhotoUrl'];
    final String content = data['content'] ?? '';
    final Timestamp? createdAt = data['createdAt'];
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(_currentUserId);
    final int likeCount = data['likeCount'] ?? 0;

    String timeAgo = '';
    if (createdAt != null) timeAgo = _formatTimeAgo(createdAt.toDate());

    return Column(
      children: [
        // O Comentário Principal
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
                child: userPhotoUrl == null ? Icon(Icons.person, size: 20, color: Colors.grey[600]) : null,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(userName, style: GoogleFonts.epilogue(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(width: 6),
                        Text(timeAgo, style: TextStyle(fontSize: 12, color: subTextColor)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(content, style: TextStyle(fontSize: 14, color: textColor)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _startReply(commentId, userName),
                          child: Text("Responder", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subTextColor)),
                        ),
                        if (data['userId'] == _currentUserId) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _commentService.deleteComment(postId: widget.postId, commentId: commentId),
                            child: Text("Excluir", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.withValues(alpha: 0.7))),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              // Botão de Like e Contagem
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _commentService.toggleCommentLike(postId: widget.postId, commentId: commentId, likes: likes),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: isLiked ? Colors.red : subTextColor,
                    ),
                  ),
                  if (likeCount > 0)
                    Text('$likeCount', style: TextStyle(fontSize: 10, color: subTextColor)),
                ],
              ),
            ],
          ),
        ),

        // Sub-lista de Respostas (Indentada)
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _commentService.getReplies(widget.postId, commentId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(left: 52), // Indentação
              child: Column(
                children: snapshot.data!.docs.map((doc) {
                  final rData = doc.data();
                  return _buildReplyTile(commentId, doc.id, rData, textColor, subTextColor, primaryColor);
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // Widget para uma resposta individual (Visualmente similar ao comentário)
  Widget _buildReplyTile(String parentCommentId, String replyId, Map<String, dynamic> data, Color textColor, Color? subTextColor, Color primaryColor) {
    final String userName = data['userName'] ?? 'Usuário';
    final String? userPhotoUrl = data['userPhotoUrl'];
    final String content = data['content'] ?? '';
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(_currentUserId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12, // Avatar menor
            backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
            child: userPhotoUrl == null ? Icon(Icons.person, size: 14, color: Colors.grey[600]) : null,
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: GoogleFonts.epilogue(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                Text(content, style: TextStyle(fontSize: 13, color: textColor)),
                if (data['userId'] == _currentUserId)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GestureDetector(
                      onTap: () => _commentService.deleteReply(postId: widget.postId, commentId: parentCommentId, replyId: replyId),
                      child: Text("Excluir", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red.withValues(alpha: 0.7))),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _commentService.toggleReplyLike(postId: widget.postId, commentId: parentCommentId, replyId: replyId, likes: likes),
            child: Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 14, color: isLiked ? Colors.red : subTextColor),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays < 7) return '${diff.inDays} d';
    return DateFormat('dd MMM').format(dt);
  }
}