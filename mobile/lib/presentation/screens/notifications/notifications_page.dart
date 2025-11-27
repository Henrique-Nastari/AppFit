// lib/presentation/screens/notifications/notifications_page.dart - CORRIGIDO

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../application/notifications/notification_service.dart';
import '../feed/post_details_page.dart';
import '../profile/profile_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService notificationService = NotificationService();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = theme.hintColor;
    const primaryColor = Color(0xFF13EC6D);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Notificações",
          style: GoogleFonts.epilogue(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: notificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: subTextColor.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text("Nenhuma notificação.", style: TextStyle(color: subTextColor)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(color: subTextColor.withValues(alpha: 0.1), height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final String senderName = data['senderName'] ?? 'Alguém';
              final String? senderPhoto = data['senderPhotoUrl'];
              final String message = data['message'] ?? '';
              final String type = data['type'] ?? 'info'; // like, comment, follow
              final String? postId = data['postId'];
              final String senderId = data['senderId'] ?? '';
              final Timestamp? createdAt = data['createdAt'];

              String timeAgo = '';
              if (createdAt != null) {
                final dt = createdAt.toDate();
                final diff = DateTime.now().difference(dt);
                if (diff.inMinutes < 60) {
                  timeAgo = '${diff.inMinutes}m';
                } else if (diff.inHours < 24) {
                  timeAgo = '${diff.inHours}h';
                } else {
                  timeAgo = '${diff.inDays}d';
                }
              }

              IconData icon;
              Color iconColor;
              if (type == 'like') {
                icon = Icons.favorite;
                iconColor = Colors.redAccent;
              } else if (type == 'comment') {
                icon = Icons.chat_bubble;
                iconColor = Colors.blueAccent;
              } else {
                icon = Icons.person_add;
                iconColor = primaryColor;
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: senderPhoto != null ? NetworkImage(senderPhoto) : null,
                      child: senderPhoto == null ? Icon(Icons.person, color: Colors.grey[600]) : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: Icon(icon, size: 10, color: iconColor),
                        ),
                      ),
                    )
                  ],
                ),
                title: RichText(
                  text: TextSpan(
                    style: TextStyle(color: textColor, fontSize: 14),
                    children: [
                      TextSpan(text: senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: " "),
                      TextSpan(text: message),
                    ],
                  ),
                ),
                trailing: Text(timeAgo, style: TextStyle(color: subTextColor, fontSize: 12)),
                onTap: () {
                  if (type == 'follow') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: senderId)));
                  } else if (postId != null) {
                    // Busca o post para navegar
                    FirebaseFirestore.instance.collection('posts').doc(postId).get().then((doc) {
                      if (doc.exists && context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailsPage(postId: postId, postData: doc.data()!)));
                      }
                    });
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}