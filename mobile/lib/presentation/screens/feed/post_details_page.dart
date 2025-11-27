// lib/presentation/screens/feed/post_details_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/feed/post_card.dart';

class PostDetailsPage extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailsPage({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  Widget build(BuildContext context) {
    // Recupera o tema para a AppBar
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Publicação",
          style: GoogleFonts.epilogue(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Reutilizamos o PostCard que já é lindo e completo!
            PostCard(
              postId: postId,
              postData: postData,
            ),
            // Espaço extra no final
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}