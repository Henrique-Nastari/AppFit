// lib/presentation/widgets/feed/post_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar datas de forma mais amigável

class PostCard extends StatelessWidget {
  final Map<String, dynamic> postData;

  const PostCard({super.key, required this.postData});

  @override
  Widget build(BuildContext context) {
    // Extraindo dados do post com segurança
    final String userName = postData['userDisplayName'] ?? 'Atleta';
    final String? userPhotoUrl = postData['userPhotoUrl'];
    final String? workoutTitle = postData['workoutTitle'];
    final String? caption = postData['caption'];
    final String? imageUrl = postData['imageUrl'];
    final Timestamp? createdAt = postData['createdAt'];
    final List<dynamic>? exercises = postData['exercises'] as List<dynamic>?; // Lista de exercícios
    final Map<String, dynamic>? metrics = postData['metrics'] as Map<String, dynamic>?; // Métricas adicionais

    String formattedDate = '';
    if (createdAt != null) {
      try {
        // Formata a data. Certifique-se de inicializar locales se necessário.
        formattedDate = DateFormat('dd \'de\' MMMM \'de\' yyyy \'às\' HH:mm', 'pt_BR').format(createdAt.toDate());
      } catch (e) {
        // Fallback caso a formatação de locale falhe
        formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate());
        print("Erro ao formatar data com locale pt_BR: $e. Usando formato padrão.");
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0), // Ocupa toda a largura
      elevation: 1, // Leve sombra para dar profundidade
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), // Cantos retos
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER DO POST: Nome do Usuário e Data ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                      ? NetworkImage(userPhotoUrl)
                      : null,
                  child: userPhotoUrl == null || userPhotoUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 24)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded( // Para evitar overflow se o nome for muito longo
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis, // Evita quebrar linha
                      ),
                      if (formattedDate.isNotEmpty)
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                // const Spacer(), // Removido para dar espaço ao nome
                // IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}), // Botão de menu (opcional)
              ],
            ),
          ),

          // --- IMAGEM DO TREINO ---
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300, // Altura fixa para as imagens
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null, // Correção aqui
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                ),
              ),
            ),

          // --- DETALHES DO TREINO (Título, Exercícios, Métricas) ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (workoutTitle != null && workoutTitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      workoutTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),

                // Exibindo os Exercícios
                if (exercises != null && exercises.isNotEmpty)
                  ...exercises.map((exerciseData) {
                    // Garantir que exerciseData é um Map
                    if (exerciseData is! Map) return const SizedBox.shrink();
                    final Map<String, dynamic> exerciseMap = Map<String, dynamic>.from(exerciseData);

                    final String exerciseName = exerciseMap['name'] ?? 'Exercício Desconhecido';
                    final String? exerciseNotes = exerciseMap['notes'];
                    final List<dynamic>? sets = exerciseMap['sets'] as List<dynamic>?;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exerciseName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (exerciseNotes != null && exerciseNotes.isNotEmpty)
                             Padding(
                               padding: const EdgeInsets.only(top: 2.0),
                               child: Text(
                                exerciseNotes,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                               ),
                             ),
                          if (sets != null && sets.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: sets.asMap().entries.map((entry) {
                                  int setIndex = entry.key;
                                  // Garantir que setData é um Map
                                  if (entry.value is! Map) return const SizedBox.shrink();
                                  Map<String, dynamic> setData = Map<String, dynamic>.from(entry.value);

                                  // Construindo a string de detalhes da série
                                  List<String> details = [];
                                  if (setData['reps'] != null) details.add('${setData['reps']} reps');
                                  if (setData['weight'] != null) details.add('${setData['weight']} kg');
                                  if (setData['distance'] != null) details.add('${setData['distance']} m');
                                  if (setData['duration'] != null) details.add('${setData['duration']} seg');
                                  if (setData['rpe'] != null) details.add('RPE ${setData['rpe']}');

                                  if (details.isNotEmpty) {
                                    return Text(
                                      '${setIndex + 1}: ${details.join(' | ')}', // Usando ' | ' como separador
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                // --- Métricas Adicionais ---
                if (metrics != null && metrics.isNotEmpty) ...[
                  if (exercises != null && exercises.isNotEmpty) const SizedBox(height: 10), // Espaço se houver exercícios
                  Wrap(
                    spacing: 8.0, // Espaço horizontal entre os chips
                    runSpacing: 4.0, // Espaço vertical entre as linhas de chips
                    children: metrics.entries.map((entry) {
                      String label = entry.key;
                      dynamic value = entry.value;
                      String displayValue = value.toString();
                      String unit = '';

                      // Melhorando os rótulos e unidades
                      if (label == 'DuracaoMin') { label = 'Duração'; unit = ' min'; }
                      if (label == 'VolumeKg') { label = 'Volume'; unit = ' kg'; }
                      if (label == 'Calorias') { unit = ' kcal'; }
                      // Adicione mais mapeamentos se necessário

                      return Chip(
                        label: Text('$label: $displayValue$unit', style: TextStyle(fontSize: 12)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        visualDensity: VisualDensity.compact, // Deixa o chip menor
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // --- LEGENDA (Caption) ---
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0, top: 4.0), // Ajuste no padding
              child: Text(
                caption,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          // const SizedBox(height: 12), // Espaço final removido, margem do Card já separa
        ],
      ),
    );
  }
}