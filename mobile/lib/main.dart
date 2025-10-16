import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import 'auth/auth_service.dart';
import 'feed/create_post_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AppFit());
}

class AppFit extends StatelessWidget {
  const AppFit({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('AppFit Feed'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: const FeedPage(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreatePostPage()),
          );
          if (created == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Postagem publicada.')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova postagem'),
      ),
    );
  }
}

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  Query<Map<String, dynamic>> _buildQuery() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _FeedMessage(
            icon: Icons.error_outline,
            message: 'Falha ao carregar o feed. Tente novamente.',
          );
        }

        final documents = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (documents.isEmpty) {
          return const _FeedMessage(
            icon: Icons.fitness_center,
            message: 'Nenhuma postagem por enquanto. Registre seu primeiro treino!',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: documents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final post = WorkoutPost.fromSnapshot(documents[index]);
            return WorkoutPostCard(post: post);
          },
        );
      },
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutPost {
  WorkoutPost({
    required this.id,
    required this.userName,
    required this.createdAt,
    this.userAvatarUrl,
    this.workoutTitle,
    this.caption,
    this.imageUrl,
    this.exercises = const [],
    this.metrics = const {},
  });

  final String id;
  final String userName;
  final DateTime? createdAt;
  final String? userAvatarUrl;
  final String? workoutTitle;
  final String? caption;
  final String? imageUrl;
  final List<WorkoutExercise> exercises;
  final Map<String, dynamic> metrics;

  factory WorkoutPost.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final userName = _stringField(
          data,
          keys: ['userDisplayName', 'username', 'athleteName'],
        ) ??
        'Atleta sem nome';
    final createdAt = _parseDate(data['createdAt'] ?? data['timestamp']);
    final userAvatarUrl = _stringField(
      data,
      keys: ['userPhotoUrl', 'photoUrl', 'avatarUrl'],
    );
    final workoutTitle = _stringField(
      data,
      keys: ['workoutName', 'workoutTitle', 'title'],
    );
    final caption = _stringField(
      data,
      keys: ['description', 'caption', 'notes'],
    );
    final imageUrl = _stringField(
      data,
      keys: ['imageUrl', 'mediaUrl'],
    );

    return WorkoutPost(
      id: snapshot.id,
      userName: userName,
      createdAt: createdAt,
      userAvatarUrl: userAvatarUrl,
      workoutTitle: workoutTitle,
      caption: caption,
      imageUrl: imageUrl,
      exercises: _parseExercises(data['exercises']),
      metrics: _parseMetrics(data['metrics']),
    );
  }

  String get initials {
    final normalized = userName.trim();
    if (normalized.isEmpty) {
      return '?';
    }
    final parts = normalized.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final part = parts.first;
      if (part.length >= 2) {
        return part.substring(0, 2).toUpperCase();
      }
      return part.substring(0, 1).toUpperCase();
    }
    final first = parts.first.isNotEmpty ? parts.first.substring(0, 1) : '';
    final last = parts.last.isNotEmpty ? parts.last.substring(0, 1) : '';
    final combined = (first + last).trim();
    if (combined.isEmpty) {
      return '?';
    }
    return combined.toUpperCase();
  }

  String get timeAgo {
    final date = createdAt;
    if (date == null) {
      return 'agora';
    }
    final difference = DateTime.now().difference(date);
    if (difference.isNegative) return 'agora';
    if (difference.inMinutes < 1) return 'agora';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min';
    if (difference.inHours < 24) return '${difference.inHours} h';
    if (difference.inDays < 7) return '${difference.inDays} d';
    final weeks = (difference.inDays / 7).floor();
    if (weeks < 4) return '$weeks sem';
    final months = (difference.inDays / 30).floor();
    if (months < 12) return '$months mes';
    final years = (difference.inDays / 365).floor();
    return '$years ano${years > 1 ? 's' : ''}';
  }

  static String? _stringField(
    Map<String, dynamic> data, {
    required List<String> keys,
    String? fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<WorkoutExercise> _parseExercises(dynamic value) {
    if (value is! List) return const [];
    return value
        .map<WorkoutExercise?>((item) {
          if (item is Map<String, dynamic>) {
            return WorkoutExercise.fromMap(item);
          }
          if (item is Map) {
            return WorkoutExercise.fromMap(
              item.map((key, v) => MapEntry(key.toString(), v)),
            );
          }
          return null;
        })
        .whereType<WorkoutExercise>()
        .toList();
  }

  static Map<String, dynamic> _parseMetrics(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return const {};
  }
}

class WorkoutExercise {
  WorkoutExercise({
    required this.name,
    this.sets = const [],
    this.notes,
  });

  final String name;
  final List<WorkoutSet> sets;
  final String? notes;

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      name: (map['name'] ?? map['exerciseName'] ?? 'Exercicio').toString(),
      notes: (map['notes'] ?? map['comment'])?.toString(),
      sets: _parseSets(map['sets']),
    );
  }

  static List<WorkoutSet> _parseSets(dynamic value) {
    if (value is! List) return const [];
    return value
        .map<WorkoutSet?>((item) {
          if (item is Map<String, dynamic>) {
            return WorkoutSet.fromMap(item);
          }
          if (item is Map) {
            return WorkoutSet.fromMap(
              item.map((key, v) => MapEntry(key.toString(), v)),
            );
          }
          return null;
        })
        .whereType<WorkoutSet>()
        .toList();
  }
}

class WorkoutSet {
  WorkoutSet({
    this.weight,
    this.reps,
    this.duration,
    this.distance,
    this.rpe,
  });

  final num? weight;
  final int? reps;
  final Duration? duration;
  final num? distance;
  final num? rpe;

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      weight: _parseNum(map['weight'] ?? map['kg'] ?? map['peso']),
      reps: _parseInt(map['reps'] ?? map['repeticoes']),
      duration: _parseDuration(map['duration'] ?? map['tempo']),
      distance: _parseNum(map['distance'] ?? map['distancia']),
      rpe: _parseNum(map['rpe']),
    );
  }

  static num? _parseNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Duration? _parseDuration(dynamic value) {
    if (value is Duration) return value;
    if (value is int) return Duration(seconds: value);
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return Duration(seconds: parsed);
      }
      final segments = value.split(':');
      if (segments.length == 3) {
        final hours = int.tryParse(segments[0]) ?? 0;
        final minutes = int.tryParse(segments[1]) ?? 0;
        final seconds = int.tryParse(segments[2]) ?? 0;
        return Duration(hours: hours, minutes: minutes, seconds: seconds);
      }
    }
    return null;
  }
}

class WorkoutPostCard extends StatelessWidget {
  const WorkoutPostCard({super.key, required this.post});

  final WorkoutPost post;

  @override
  Widget build(BuildContext context) {
    final exercises = post.exercises;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.timeAgo,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  tooltip: 'Opcoes',
                  onPressed: () {},
                ),
              ],
            ),
          ),
          if (post.imageUrl != null)
            _FeedImage(imageUrl: post.imageUrl!),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.workoutTitle != null)
                  Text(
                    post.workoutTitle!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                if (post.caption != null) ...[
                  if (post.workoutTitle != null) const SizedBox(height: 8),
                  Text(
                    post.caption!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (exercises.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  for (final exercise in exercises)
                    _ExerciseSummary(exercise: exercise),
                ],
                if (post.metrics.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: post.metrics.entries
                        .map(
                          (entry) => Chip(
                            label: Text('${entry.key}: ${entry.value}'),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (post.userAvatarUrl != null && post.userAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(post.userAvatarUrl!),
      );
    }
    return CircleAvatar(
      child: Text(post.initials),
    );
  }
}

class _FeedImage extends StatelessWidget {
  const _FeedImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Ink.image(
        image: NetworkImage(imageUrl),
        fit: BoxFit.cover,
        child: const SizedBox.expand(),
        onImageError: (_, __) {},
      ),
    );
  }
}

class _ExerciseSummary extends StatelessWidget {
  const _ExerciseSummary({required this.exercise});

  final WorkoutExercise exercise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (exercise.sets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < exercise.sets.length; index++)
                    Text(
                      _formatSet(index + 1, exercise.sets[index]),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          if (exercise.notes != null && exercise.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 4),
              child: Text(
                exercise.notes!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor),
              ),
            ),
        ],
      ),
    );
  }

  String _formatSet(int index, WorkoutSet set) {
    final segments = <String>[];
    if (set.reps != null) {
      segments.add('${set.reps} reps');
    }
    if (set.weight != null) {
      segments.add('${set.weight} kg');
    }
    if (set.distance != null) {
      segments.add('${set.distance} m');
    }
    if (set.duration != null) {
      final minutes = set.duration!.inMinutes;
      final seconds = set.duration!.inSeconds.remainder(60).toString().padLeft(2, '0');
      segments.add('${minutes}m ${seconds}s');
    }
    if (set.rpe != null) {
      segments.add('RPE ${set.rpe}');
    }
    final detail = segments.isEmpty ? 'Sem detalhes' : segments.join(' | ');
    return 'Serie $index: $detail';
  }
}
