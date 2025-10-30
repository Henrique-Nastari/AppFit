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
  });

  final _WorkoutExerciseForm exerciseForm;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
    );
  }
}

class _WorkoutExerciseForm {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  Exercise? toExercise() {
    final name = nameController.text.trim();
    if (name.isEmpty) return null;
    final notes = notesController.text.trim();
    return Exercise(
      name: name,
      notes: notes.isEmpty ? null : notes,
      sets: const [],
    );
  }

  void dispose() {
    nameController.dispose();
    notesController.dispose();
  }
}
