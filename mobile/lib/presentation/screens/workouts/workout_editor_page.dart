import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/workout.dart';
import '../../../services/firestore_repository.dart';

class WorkoutEditorPage extends StatefulWidget {
  const WorkoutEditorPage({super.key});

  @override
  State<WorkoutEditorPage> createState() => _WorkoutEditorPageState();
}

class _WorkoutEditorPageState extends State<WorkoutEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final List<_WorkoutExerciseForm> _exercises = [_WorkoutExerciseForm()];
  final FirestoreRepository _repository = FirestoreRepository();

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  void _addExercise() {
    setState(() {
      _exercises.add(_WorkoutExerciseForm());
    });
  }

  void _removeExercise(int index) {
    if (_exercises.length == 1) return;
    setState(() {
      _exercises.removeAt(index).dispose();
    });
  }

  Future<void> _saveWorkout() async {
    if (_isSaving) return;
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faca login para salvar treinos.')),
      );
      return;
    }

    form.save();

    final exercises = _exercises
        .map((exercise) => exercise.toExercise())
        .where((exercise) => exercise != null)
        .cast<Exercise>()
        .toList();

    final workout = Workout(
      ownerId: user.uid,
      title: _titleController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      exercises: exercises,
      visibility: 'private',
    );

    setState(() => _isSaving = true);
    try {
      await _repository.createWorkout(workout);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar treino: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo treino'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nome do treino',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe um nome para o treino';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas gerais (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              Text(
                'Exercicios',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _exercises.length; i++)
                _WorkoutExerciseCard(
                  key: ValueKey('exercise_$i'),
                  exerciseForm: _exercises[i],
                  canRemove: _exercises.length > 1,
                  onRemove: () => _removeExercise(i),
                  onChanged: () => setState(() {}),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar exercicio'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _saveWorkout,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar treino'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutExerciseCard extends StatelessWidget {
  const _WorkoutExerciseCard({
    super.key,
    required this.exerciseForm,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final _WorkoutExerciseForm exerciseForm;
  final VoidCallback onRemove;
  final bool canRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: exerciseForm.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do exercicio',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome do exercicio';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: canRemove ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remover exercicio',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: exerciseForm.notesController,
              decoration: const InputDecoration(
                labelText: 'Notas ou dicas (opcional)',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text(
              'Series',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...List.generate(exerciseForm.sets.length, (index) {
              final setForm = exerciseForm.sets[index];
              return _WorkoutSetTile(
                key: ValueKey(setForm),
                index: index,
                setForm: setForm,
                onRemove: () {
                  exerciseForm.removeSet(index);
                  onChanged();
                },
                canRemove: exerciseForm.sets.length > 1,
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  exerciseForm.addSet();
                  onChanged();
                },
                icon: const Icon(Icons.add),
                label: const Text('Adicionar serie'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutExerciseForm {
  _WorkoutExerciseForm() {
    addSet();
  }

  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final List<_WorkoutSetForm> sets = [];

  void addSet() {
    sets.add(_WorkoutSetForm());
  }

  void removeSet(int index) {
    if (sets.length == 1) return;
    sets.removeAt(index).dispose();
  }

  Exercise? toExercise() {
    final name = nameController.text.trim();
    if (name.isEmpty) return null;
    final notes = notesController.text.trim();
    final mappedSets = sets
        .map((set) => set.toSetEntry())
        .where((set) => set != null)
        .cast<SetEntry>()
        .toList();
    return Exercise(
      name: name,
      notes: notes.isEmpty ? null : notes,
      sets: mappedSets,
    );
  }

  void dispose() {
    nameController.dispose();
    notesController.dispose();
    for (final set in sets) {
      set.dispose();
    }
  }
}

class _WorkoutSetTile extends StatelessWidget {
  const _WorkoutSetTile({
    super.key,
    required this.index,
    required this.setForm,
    required this.onRemove,
    required this.canRemove,
  });

  final int index;
  final _WorkoutSetForm setForm;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.surfaceVariant.withOpacity(0.5);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Serie ${index + 1}',
                style: theme.textTheme.titleSmall,
              ),
              const Spacer(),
              IconButton(
                onPressed: canRemove ? onRemove : null,
                tooltip: 'Remover serie',
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: setForm.repsController,
                  decoration: const InputDecoration(
                    labelText: 'Repeticoes',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: setForm.weightController,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: setForm.restController,
                  decoration: const InputDecoration(
                    labelText: 'Descanso (seg)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutSetForm {
  final TextEditingController repsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController restController = TextEditingController();

  SetEntry? toSetEntry() {
    final reps = int.tryParse(repsController.text.trim());
    final weight = double.tryParse(weightController.text.trim());
    final rest = int.tryParse(restController.text.trim());

    if (reps == null && weight == null && rest == null) {
      return null;
    }

    return SetEntry(
      reps: reps,
      weightKg: weight,
      restSeconds: rest,
    );
  }

  void dispose() {
    repsController.dispose();
    weightController.dispose();
    restController.dispose();
  }
}
