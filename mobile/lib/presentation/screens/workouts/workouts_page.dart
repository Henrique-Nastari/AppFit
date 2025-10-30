import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/workout.dart';
import '../../../services/firestore_repository.dart';
import 'workout_editor_page.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  final FirestoreRepository _repository = FirestoreRepository();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meus treinos')),
        body: const Center(
          child: Text('Entre na sua conta para salvar treinos.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus treinos'),
      ),
      body: StreamBuilder<List<Workout>>(
        stream: _repository.listWorkouts(ownerId: user.uid, limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Falha ao carregar treinos: ${snapshot.error}'),
            );
          }

          final workouts = snapshot.data ?? const <Workout>[];

          if (workouts.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final workout = workouts[index];
              final summary = workout.summary();

              final exerciseCount = summary['exerciseCount'] as int? ?? 0;
              final totalSets = summary['totalSets'] as int? ?? 0;
              final durationMinutes = summary['durationMinutes'] as int?;

              return Card(
                child: ListTile(
                  title: Text(workout.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (workout.notes != null && workout.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            workout.notes!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _SummaryChip(
                              icon: Icons.fitness_center,
                              label: '$exerciseCount exercicio${exerciseCount == 1 ? '' : 's'}',
                            ),
                            _SummaryChip(
                              icon: Icons.repeat,
                              label: '$totalSets serie${totalSets == 1 ? '' : 's'}',
                            ),
                            if (durationMinutes != null)
                              _SummaryChip(
                                icon: Icons.timer,
                                label: '$durationMinutes min',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: workouts.length,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);
          final created = await navigator.push<bool>(
            MaterialPageRoute(
              builder: (_) => const WorkoutEditorPage(),
            ),
          );
          if (!mounted) return;
          if (created == true) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Treino salvo com sucesso.')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo treino'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Voce ainda nao salvou nenhum treino.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie um esqueleto com os exercicios que voce mais usa para agilizar seus posts.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
