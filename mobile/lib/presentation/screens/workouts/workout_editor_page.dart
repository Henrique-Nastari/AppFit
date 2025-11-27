// lib/presentation/screens/workouts/workout_editor_page.dart - COM PICKERS ROLÁVEIS

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart'; // Necessário para o Picker
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/workout.dart';
import '../../../services/firestore_repository.dart';

class WorkoutEditorPage extends StatefulWidget {
  const WorkoutEditorPage({super.key});

  @override
  State<WorkoutEditorPage> createState() => _WorkoutEditorPageState();
}

class _WorkoutEditorPageState extends State<WorkoutEditorPage> {
  // --- LÓGICA INTACTA ---
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
        const SnackBar(content: Text('Faça login para salvar treinos.')),
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

  // --- UI (NOVO VISUAL) ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color backgroundColor = isDark ? const Color(0xFF102218) : const Color(0xFFF6F8F7);
    final Color surfaceColor = isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1C1C1C);
    final Color subTextColor = isDark ? Colors.white60 : const Color(0xFF797979);
    const Color primaryColor = Color(0xFF13EC6D);

    final InputDecoration inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
      hintStyle: TextStyle(color: subTextColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.transparent : const Color(0xFFE1E1E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.transparent : const Color(0xFFE1E1E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: backgroundColor.withValues(alpha: 0.9),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: textColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Text(
                      "Novo Treino",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.epilogue(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  _isSaving
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2))
                      : TextButton(
                    onPressed: _saveWorkout,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Salvar",
                      style: GoogleFonts.epilogue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- CORPO ---
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: inputDecoration.copyWith(hintText: "Nome do treino"),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Informe um nome' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: inputDecoration.copyWith(hintText: "Notas gerais (opcional)"),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 32),
                    Text(
                      "Exercícios",
                      style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 16),

                    for (var i = 0; i < _exercises.length; i++)
                      _WorkoutExerciseCard(
                        key: ValueKey('exercise_$i'),
                        exerciseForm: _exercises[i],
                        canRemove: _exercises.length > 1,
                        onRemove: () => _removeExercise(i),
                        onChanged: () => setState(() {}),
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F7F7),
                        cardColor: surfaceColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        primaryColor: primaryColor,
                      ),

                    const SizedBox(height: 24),

                    InkWell(
                      onTap: _addExercise,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFE1E1E1), width: 2),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? Colors.transparent : Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              "Adicionar exercício",
                              style: GoogleFonts.epilogue(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
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
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.primaryColor,
  });

  final _WorkoutExerciseForm exerciseForm;
  final VoidCallback onRemove;
  final bool canRemove;
  final VoidCallback onChanged;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final minimalInputDecoration = InputDecoration(
      border: InputBorder.none,
      hintStyle: TextStyle(color: subTextColor),
      contentPadding: EdgeInsets.zero,
      isDense: true,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: exerciseForm.nameController,
                  style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                  decoration: minimalInputDecoration.copyWith(hintText: "Nome do exercício"),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Obrigatório' : null,
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(Icons.delete_outline, color: subTextColor),
                  tooltip: 'Remover exercício',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const Divider(height: 24),

          TextFormField(
            controller: exerciseForm.notesController,
            style: TextStyle(fontSize: 14, color: textColor),
            decoration: minimalInputDecoration.copyWith(hintText: "Notas ou dicas (opcional)"),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),

          Text("Séries", style: GoogleFonts.epilogue(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 12),

          ...List.generate(exerciseForm.sets.length, (index) {
            return _WorkoutSetTile(
              key: ValueKey(exerciseForm.sets[index]),
              index: index,
              setForm: exerciseForm.sets[index],
              onRemove: () {
                exerciseForm.removeSet(index);
                onChanged();
              },
              canRemove: exerciseForm.sets.length > 1,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              primaryColor: primaryColor,
            );
          }),

          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              exerciseForm.addSet();
              onChanged();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.add, color: primaryColor, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    "Adicionar série",
                    style: GoogleFonts.epilogue(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutSetTile extends StatelessWidget {
  const _WorkoutSetTile({
    super.key,
    required this.index,
    required this.setForm,
    required this.onRemove,
    required this.canRemove,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.primaryColor,
  });

  final int index;
  final _WorkoutSetForm setForm;
  final VoidCallback onRemove;
  final bool canRemove;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color primaryColor;

  // --- LÓGICA DO PICKER (Rodinha) ---
  void _showWheelPicker(BuildContext context, {
    required String title,
    required TextEditingController controller,
    required bool isDecimal,
    required double max,
    String suffix = '',
  }) {
    // Gera lista de valores
    List<String> values;
    if (isDecimal) {
      // Para peso: 0.0, 0.5, 1.0 ... 500.0
      values = List.generate((max * 2).toInt() + 1, (i) => (i / 2).toString());
    } else {
      // Para reps/tempo: 0, 1, 2 ...
      values = List.generate(max.toInt() + 1, (i) => i.toString());
    }

    // Encontra índice inicial
    int initialIndex = 0;
    try {
      double current = double.parse(controller.text);
      if (isDecimal) {
        initialIndex = (current * 2).toInt();
      } else {
        initialIndex = current.toInt();
      }
    } catch (_) {}

    // Garante limites
    if (initialIndex < 0) initialIndex = 0;
    if (initialIndex >= values.length) initialIndex = values.length - 1;

    final FixedExtentScrollController scrollController =
    FixedExtentScrollController(initialItem: initialIndex);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      builder: (BuildContext context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              // Barra de título do Picker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: textColor.withValues(alpha: 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("OK", style: TextStyle(color: primaryColor)),
                    ),
                  ],
                ),
              ),
              // A Rodinha (CupertinoPicker)
              Expanded(
                child: CupertinoPicker(
                  scrollController: scrollController,
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  // Atualiza o texto enquanto gira
                  onSelectedItemChanged: (int selectedItem) {
                    controller.text = values[selectedItem];
                  },
                  children: values.map((val) => Center(
                    child: Text(
                      "$val $suffix",
                      style: TextStyle(color: textColor),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Série ${index + 1}", style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (canRemove)
                InkWell(
                  onTap: onRemove,
                  child: Icon(Icons.close, size: 16, color: subTextColor),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPickerInput(context, "Repetições", setForm.repsController, false, 100, ""),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPickerInput(context, "Peso (kg)", setForm.weightController, true, 500, "kg"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPickerInput(context, "Descanso (seg)", setForm.restController, false, 600, "s"),
        ],
      ),
    );
  }

  Widget _buildPickerInput(BuildContext context, String label, TextEditingController controller, bool isDecimal, double max, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: subTextColor, fontSize: 11)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showWheelPicker(context,
              title: label,
              controller: controller,
              isDecimal: isDecimal,
              max: max,
              suffix: suffix
          ),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              // Usamos IgnorePointer para que o TextField apenas mostre o valor,
              // mas o toque seja capturado pelo GestureDetector acima
              child: IgnorePointer(
                child: TextFormField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- CLASSES LÓGICAS (100% INTACTAS) ---
class _WorkoutExerciseForm {
  _WorkoutExerciseForm() { addSet(); }
  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final List<_WorkoutSetForm> sets = [];
  void addSet() => sets.add(_WorkoutSetForm());
  void removeSet(int index) { if (sets.length > 1) sets.removeAt(index).dispose(); }
  Exercise? toExercise() {
    final name = nameController.text.trim();
    if (name.isEmpty) return null;
    final notes = notesController.text.trim();
    final mappedSets = sets.map((set) => set.toSetEntry()).where((set) => set != null).cast<SetEntry>().toList();
    return Exercise(name: name, notes: notes.isEmpty ? null : notes, sets: mappedSets);
  }
  void dispose() { nameController.dispose(); notesController.dispose(); for (final set in sets) set.dispose(); }
}

class _WorkoutSetForm {
  final TextEditingController repsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController restController = TextEditingController();
  SetEntry? toSetEntry() {
    final reps = int.tryParse(repsController.text.trim());
    final weight = double.tryParse(weightController.text.trim());
    final rest = int.tryParse(restController.text.trim());
    if (reps == null && weight == null && rest == null) return null;
    return SetEntry(reps: reps, weightKg: weight, restSeconds: rest);
  }
  void dispose() { repsController.dispose(); weightController.dispose(); restController.dispose(); }
}