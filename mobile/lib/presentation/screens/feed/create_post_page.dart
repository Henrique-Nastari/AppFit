// features/feed/screens/create_post_page.dart - ATUALIZADO (com CÃ¢mera)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../application/feed/post_service.dart'; 
import '../../../models/workout.dart';
import '../../../services/firestore_repository.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  // --- A LÃ“GICA DE UI E FORMULÃRIO (MANTIDA) ---
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  final _durationController = TextEditingController();
  final _volumeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _moodController = TextEditingController();

  final List<_ExerciseFormData> _exercises = [];
  bool _isSubmitting = false;

  // --- NOSSAS ADICOES (MANTIDAS) ---
  final PostService _postService = PostService();
  final FirestoreRepository _firestoreRepository = FirestoreRepository();
  Workout? _selectedWorkout;
  File? _imageFile;

  // --- METODOS DE CICLO DE VIDA (MANTIDOS) ---
  @override
  void initState() {
    super.initState();
    _addExercise();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    _durationController.dispose();
    _volumeController.dispose();
    _caloriesController.dispose();
    _moodController.dispose();
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  // --- NOSSAS NOVAS FUNÃ‡Ã•ES ---
  // --- NOSSAS NOVAS FUNCOES ---
  /// **NOVO:** Mostra as opcoes (camera ou galeria)
  Future<void> _showImagePickerOptions() async {
    // Esconde o teclado se estiver aberto
    FocusScope.of(context).unfocus();
    
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Selecionar da galeria'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tirar foto com a camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// **MODIFICADO:** Agora aceita um ImageSource
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70, // Comprime a imagem para economizar espaÃ§o
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
  Future<void> _openWorkoutPicker() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faca login para acessar seus treinos salvos.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<Workout>(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: StreamBuilder<List<Workout>>(
              stream: _firestoreRepository.listWorkouts(ownerId: user.uid, limit: 50),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Erro ao carregar treinos: '),
                    ),
                  );
                }

                final workouts = snapshot.data ?? const <Workout>[];
                if (workouts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Nenhum treino salvo ainda.'),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    final summary = workout.summary();
                    final exerciseCount = summary['exerciseCount'] as int? ?? 0;
                    final totalSets = summary['totalSets'] as int? ?? 0;

                    return ListTile(
                      title: Text(workout.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (workout.notes != null && workout.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                workout.notes!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '$exerciseCount exercicio(s) | $totalSets serie(s)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.of(bottomSheetContext).pop(workout),
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemCount: workouts.length,
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    _applyWorkoutTemplate(selected);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Treino "${selected.title}" carregado.')),
    );
  }

  void _applyWorkoutTemplate(Workout workout) {
    final newExercises = workout.exercises.isEmpty
        ? <_ExerciseFormData>[_ExerciseFormData()]
        : workout.exercises
            .map(_ExerciseFormData.fromWorkoutExercise)
            .toList();

    for (final exercise in _exercises) {
      exercise.dispose();
    }

    setState(() {
      _selectedWorkout = workout;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = workout.title;
      }
      _exercises
        ..clear()
        ..addAll(newExercises);
    });
  }

  void _clearSelectedWorkout() {
    setState(() {
      _selectedWorkout = null;
    });
  }

  /// Funcao de "Publicar" (Refatorada)
  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    final form = _formKey.currentState;
    if (form == null) return;
    
    if (!form.validate()) return;
    
    FocusScope.of(context).unfocus();
    setState(() { _isSubmitting = true; });

    try {
      final postData = _buildPostData(); 
      
      await _postService.publishPost(
        postData: postData,
        imageFile: _imageFile,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);

    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: ${error.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  /// Constroi o mapa de dados (Mantido)
  Map<String, dynamic> _buildPostData() {
    final caption = _captionController.text.trim();
    final title = _titleController.text.trim();
    final exercises = _exercises
        .map((exercise) => exercise.toMap())
        .where((map) => map['name'] != null)
        .toList();

    final metrics = <String, dynamic>{};
    final duration = int.tryParse(_durationController.text.trim());
    if (duration != null) {
      metrics['DuracaoMin'] = duration;
    }
    final volume = double.tryParse(_volumeController.text.trim());
    if (volume != null) {
      metrics['VolumeKg'] = volume;
    }
    final calories = int.tryParse(_caloriesController.text.trim());
    if (calories != null) {
      metrics['Calorias'] = calories;
    }
    final mood = _moodController.text.trim();
    if (mood.isNotEmpty) {
      metrics['Humor'] = mood;
    }

    return <String, dynamic>{
      'workoutTitle': title.isNotEmpty ? title : null,
      'caption': caption.isNotEmpty ? caption : null,
      'exercises': exercises,
      'metrics': metrics.isEmpty ? null : metrics,
    }..removeWhere((key, value) {
        if (value == null) return true;
        if (value is String && value.trim().isEmpty) return true;
        if (value is List && value.isEmpty) return true;
        return false;
      });
  }


  // --- FUNCOES DE UI (MANTIDAS) ---
  void _addExercise() {
    setState(() {
      _exercises.add(_ExerciseFormData());
    });
  }

  void _removeExercise(int index) {
    if (_exercises.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mantenha pelo menos um exercicio.')),
      );
      return;
    }
    setState(() {
      final removed = _exercises.removeAt(index);
      removed.dispose();
    });
  }

  // --- MÃ‰TODO BUILD (COM UMA MODIFICAÃ‡ÃƒO NO onTap) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova postagem'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publicar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // --- SEÃ‡ÃƒO DE FOTO (MODIFICADA) ---
                _buildHeadline('Foto do Treino (Opcional)'),
                GestureDetector(
                  onTap: _showImagePickerOptions, // <-- MUDANÃ‡A AQUI
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Icon(
                              Icons.add_a_photo,
                              color: Colors.grey,
                              size: 50,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                // --- FIM DA SEÃ‡ÃƒO ---

                _buildHeadline('Detalhes principais'),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _openWorkoutPicker,
                    icon: const Icon(Icons.library_books),
                    label: const Text('Carregar treino salvo'),
                  ),
                ),
                if (_selectedWorkout != null) ...[
                  const SizedBox(height: 12),
                  _SelectedWorkoutBanner(
                    workout: _selectedWorkout!,
                    onClear: _clearSelectedWorkout,
                  ),
                ],
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titulo do treino',
                    hintText: 'Por exemplo: Peito e triceps',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _captionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descricao ou notas gerais',
                    hintText: 'Compartilhe como foi o treino, PRs, sensacoes...',
                  ),
                ),
                
                const SizedBox(height: 20),
                _buildHeadline('Exercicios'),
                ..._buildExerciseForms(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar exercicio'),
                  ),
                ),
                const SizedBox(height: 20),
                _buildHeadline('Metricas adicionais'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duracao (min)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _volumeController,
                        decoration: const InputDecoration(
                          labelText: 'Volume (kg)',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _caloriesController,
                        decoration: const InputDecoration(
                          labelText: 'Calorias',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _moodController,
                        decoration: const InputDecoration(
                          labelText: 'Humor/energia',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: const Icon(Icons.check),
                    label: const Text('Salvar e publicar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- O RESTO DO CÃ“DIGO (NENHUMA MUDANÃ‡A ABAIXO DAQUI) ---

  List<Widget> _buildExerciseForms() {
    return List<Widget>.generate(_exercises.length, (index) {
      final exercise = _exercises[index];
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Exercicio ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remover exercicio',
                    onPressed: () => _removeExercise(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              TextFormField(
                controller: exercise.nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do exercicio',
                  hintText: 'Por exemplo: Supino reto',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do exercicio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: exercise.notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Series',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...List.generate(exercise.sets.length, (setIndex) {
                final setForm = exercise.sets[setIndex];
                return _SetFormRow(
                  key: ValueKey(setForm),
                  index: setIndex,
                  setForm: setForm,
                  onRemove: () {
                    setState(() {
                      exercise.removeSet(setIndex);
                    });
                  },
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      exercise.addSet();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar serie'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeadline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

class _SelectedWorkoutBanner extends StatelessWidget {
  const _SelectedWorkoutBanner({
    required this.workout,
    required this.onClear,
  });

  final Workout workout;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final summary = workout.summary();
    final exerciseCount = summary['exerciseCount'] as int? ?? 0;
    final totalSets = summary['totalSets'] as int? ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$exerciseCount exercicio(s) | $totalSets serie(s)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (workout.notes != null && workout.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        workout.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: const Text('Remover'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetFormRow extends StatelessWidget {
  const _SetFormRow({
    super.key,
    required this.index,
    required this.setForm,
    required this.onRemove,
  });

  final int index;
  final _SetFormData setForm;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Serie ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Remover serie',
                  onPressed: onRemove,
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
                      labelText: 'Reps',
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
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: setForm.distanceController,
                    decoration: const InputDecoration(
                      labelText: 'Distancia (m)',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: setForm.durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duracao (seg)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: setForm.rpeController,
                    decoration: const InputDecoration(
                      labelText: 'RPE',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseFormData {
  _ExerciseFormData({
    String? initialName,
    String? initialNotes,
    List<_SetFormData>? initialSets,
  }) {
    if (initialName != null && initialName.isNotEmpty) {
      nameController.text = initialName;
    }
    if (initialNotes != null && initialNotes.isNotEmpty) {
      notesController.text = initialNotes;
    }
    if (initialSets != null && initialSets.isNotEmpty) {
      sets.addAll(initialSets);
    } else {
      addSet();
    }
  }

  factory _ExerciseFormData.fromWorkoutExercise(Exercise exercise) {
    final initialSets = exercise.sets.isEmpty
        ? null
        : exercise.sets.map(_SetFormData.fromSetEntry).toList();
    return _ExerciseFormData(
      initialName: exercise.name,
      initialNotes: exercise.notes,
      initialSets: initialSets,
    );
  }

  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final List<_SetFormData> sets = [];

  void addSet({_SetFormData? set}) {
    sets.add(set ?? _SetFormData());
  }

  void removeSet(int index) {
    if (sets.length == 1) {
      return;
    }
    sets.removeAt(index).dispose();
  }

  Map<String, dynamic> toMap() {
    final name = nameController.text.trim();
    if (name.isEmpty) return {};
    final notes = notesController.text.trim();
    final setsMap = sets
        .map((set) => set.toMap())
        .where((map) => map.isNotEmpty)
        .toList();
    return <String, dynamic>{
      'name': name,
      if (notes.isNotEmpty) 'notes': notes,
      if (setsMap.isNotEmpty) 'sets': setsMap,
    };
  }

  void dispose() {
    nameController.dispose();
    notesController.dispose();
    for (final set in sets) {
      set.dispose();
    }
  }
}

class _SetFormData {
  _SetFormData({
    int? reps,
    double? weight,
    double? distance,
    int? duration,
    double? rpe,
  }) {
    if (reps != null) repsController.text = reps.toString();
    if (weight != null) weightController.text = weight.toString();
    if (distance != null) distanceController.text = distance.toString();
    if (duration != null) durationController.text = duration.toString();
    if (rpe != null) rpeController.text = rpe.toString();
  }

  factory _SetFormData.fromSetEntry(SetEntry entry) {
    return _SetFormData(
      reps: entry.reps,
      weight: entry.weightKg,
      duration: entry.durationSeconds,
    );
  }

  final TextEditingController repsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController distanceController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController rpeController = TextEditingController();

  Map<String, dynamic> toMap() {
    final reps = int.tryParse(repsController.text.trim());
    final weight = double.tryParse(weightController.text.trim());
    final distance = double.tryParse(distanceController.text.trim());
    final durationSeconds = int.tryParse(durationController.text.trim());
    final rpe = double.tryParse(rpeController.text.trim());

    return <String, dynamic>{
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (distance != null) 'distance': distance,
      if (durationSeconds != null) 'duration': durationSeconds,
      if (rpe != null) 'rpe': rpe,
    };
  }

  void dispose() {
    repsController.dispose();
    weightController.dispose();
    distanceController.dispose();
    durationController.dispose();
    rpeController.dispose();
  }
}





