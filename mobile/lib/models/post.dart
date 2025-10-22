import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String? id;
  final String ownerId;
  final String ownerEmail;
  final String content;
  final String? workoutId; // link opcional para um treino
  final String visibility; // 'public' | 'private'
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;

  const Post({
    this.id,
    required this.ownerId,
    required this.ownerEmail,
    required this.content,
    this.workoutId,
    this.visibility = 'public',
    this.likeCount = 0,
    this.commentCount = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'ownerEmail': ownerEmail,
        'content': content,
        if (workoutId != null) 'workoutId': workoutId,
        'visibility': visibility,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Post(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      ownerEmail: data['ownerEmail'] as String? ?? '',
      content: data['content'] as String? ?? '',
      workoutId: data['workoutId'] as String?,
      visibility: data['visibility'] as String? ?? 'public',
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}