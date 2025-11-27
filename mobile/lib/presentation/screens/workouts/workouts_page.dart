// lib/presentation/screens/workouts/workouts_page.dart - VISUAL STITCH

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Fonte Epilogue
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
  final user = FirebaseAuth.instance.currentUser;

  void _navigateToEditor({Workout? workout}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WorkoutEditorPage(),
        // Se tivéssemos edição, passaríamos o workout aqui
        // settings: RouteSettings(arguments: workout),
      ),
    );

    if (result == true) {
      setState(() {}); // Recarrega a lista após salvar
    }
  }

  Future<void> _deleteWorkout(String workoutId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir treino?'),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.deleteWorkout(workoutId);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("Faça login para ver seus treinos."));
    }

    // --- DEFINIÇÃO DE CORES DO TEMA ---
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color surfaceColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final Color textColor = theme.colorScheme.onSurface;
    final Color subTextColor = theme.hintColor;
    const Color primaryColor = Color(0xFF13EC6D); // Verde Neon Stitch
    final Color borderColor = theme.dividerColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      // Usamos SafeArea + Column para o cabeçalho customizado em vez de AppBar
      body: SafeArea(
        child: Column(
          children: [
            // --- CABEÇALHO CUSTOMIZADO ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Meus Treinos",
                    style: GoogleFonts.epilogue(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            // --- LISTA DE TREINOS ---
            Expanded(
              child: StreamBuilder<List<Workout>>(
                stream: _repository.listWorkouts(ownerId: user!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }
                  final workouts = snapshot.data;
                  if (workouts == null || workouts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center, size: 64, color: subTextColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum treino salvo.',
                            style: GoogleFonts.epilogue(fontSize: 18, color: subTextColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crie seu primeiro treino no botão abaixo.',
                            style: GoogleFonts.epilogue(fontSize: 14, color: subTextColor),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: workouts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      return _buildWorkoutCard(
                        workout: workout,
                        surfaceColor: surfaceColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        primaryColor: primaryColor,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // --- BOTÃO FLUTUANTE (FAB) ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditor(),
        backgroundColor: primaryColor,
        foregroundColor: Colors.black, // Texto/ícone preto no verde neon
        elevation: 4,
        icon: const Icon(Icons.add),
        label: Text(
          "Novo Treino",
          style: GoogleFonts.epilogue(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- WIDGET DO CARD DE TREINO CUSTOMIZADO ---
  Widget _buildWorkoutCard({
    required Workout workout,
    required Color surfaceColor,
    required Color textColor,
    required Color subTextColor,
    required Color primaryColor,
  }) {
    final int exerciseCount = workout.exercises.length;
    final int totalSets = workout.exercises.fold(0, (sum, ex) => sum + ex.sets.length);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToEditor(workout: workout), // Abre para editar
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Ícone do Treino com fundo colorido
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fitness_center, color: primaryColor),
                ),
                const SizedBox(width: 16),

                // Textos (Título e Subtítulo)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.title,
                        style: GoogleFonts.epilogue(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$exerciseCount exercícios • $totalSets séries",
                        style: GoogleFonts.epilogue(
                          fontSize: 13,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu de Opções (Editar/Excluir)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: subTextColor),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _navigateToEditor(workout: workout);
                    } else if (value == 'delete') {
                      _deleteWorkout(workout.id!);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Editar')],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 12), Text('Excluir', style: TextStyle(color: Colors.red))],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}