import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../domain/workout_models.dart';

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
