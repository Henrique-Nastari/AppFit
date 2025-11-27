// lib/presentation/screens/progress/progress_page.dart - ABAS FUNCIONAIS

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../application/profile/profile_service.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final ProfileService _profileService = ProfileService();
  late String _currentUserId;

  // Estado dos Filtros
  int _selectedDateFilter = 1; // 0=7 dias, 1=30 dias, 2=Tudo
  int _selectedCategoryFilter = 2; // 0=Força, 1=Cardio, 2=Geral (Começa em Geral)

  final List<String> _dateFilterLabels = ["7 Dias", "30 Dias", "Todo o Período"];

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  // Retorna a data de corte
  DateTime? _getStartDate() {
    final now = DateTime.now();
    if (_selectedDateFilter == 0) return now.subtract(const Duration(days: 7));
    if (_selectedDateFilter == 1) return now.subtract(const Duration(days: 30));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF102218) : const Color(0xFFF6F8F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white60 : Colors.grey[600]!;
    const primaryColor = Color(0xFF13EC6D);
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300]!;

    if (_currentUserId.isEmpty) {
      return Scaffold(backgroundColor: backgroundColor, body: const Center(child: Text("Faça login.")));
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- CABEÇALHO ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Meu Desempenho",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ),
                  IconButton(icon: Icon(Icons.ios_share, color: textColor), onPressed: () {}),
                ],
              ),
            ),

            // --- FILTROS DE DATA (CHIPS) ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: List.generate(_dateFilterLabels.length, (index) {
                  final isSelected = _selectedDateFilter == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDateFilter = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primaryColor : borderColor,
                        ),
                      ),
                      child: Text(
                        _dateFilterLabels[index],
                        style: TextStyle(
                          color: isSelected ? primaryColor : subTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // --- CONTEÚDO (DADOS) ---
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _profileService.getUserPosts(_currentUserId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final allDocs = snapshot.data!.docs;
                  final startDate = _getStartDate();

                  // --- LÓGICA DE FILTRAGEM DUPLA (DATA + CATEGORIA) ---
                  final docs = allDocs.where((doc) {
                    final data = doc.data();

                    // 1. Filtro de Data
                    final Timestamp? created = data['createdAt'];
                    if (created != null && startDate != null) {
                      if (!created.toDate().isAfter(startDate)) return false;
                    }

                    // 2. Filtro de Categoria (Aba)
                    final metrics = data['metrics'] as Map<String, dynamic>?;
                    final double volume = (metrics?['VolumeKg'] as num?)?.toDouble() ?? 0.0;

                    if (_selectedCategoryFilter == 0) {
                      // Aba FORÇA: Só mostra se tiver Volume > 0
                      return volume > 0;
                    } else if (_selectedCategoryFilter == 1) {
                      // Aba CARDIO: Só mostra se NÃO tiver Volume (ou for 0)
                      return volume == 0;
                    }
                    // Aba GERAL (2): Mostra tudo
                    return true;

                  }).toList();
                  // -----------------------------------------------------

                  // --- CÁLCULOS DOS TOTAIS ---
                  final int totalWorkouts = docs.length;

                  final int totalMinutes = docs.fold(0, (sum, doc) {
                    final m = doc.data()['metrics'] as Map<String, dynamic>?;
                    return sum + (m?['DuracaoMin'] as int? ?? 0);
                  });

                  final double totalVolume = docs.fold(0.0, (sum, doc) {
                    final m = doc.data()['metrics'] as Map<String, dynamic>?;
                    final vol = m?['VolumeKg'];
                    return sum + (vol is num ? vol.toDouble() : 0.0);
                  });

                  final int totalCalories = docs.fold(0, (sum, doc) {
                    final m = doc.data()['metrics'] as Map<String, dynamic>?;
                    return sum + (m?['Calorias'] as int? ?? 0);
                  });

                  // Lógica de PRs (Recordes)
                  final Map<String, double> prs = {};
                  for (var doc in docs) {
                    final exercises = doc.data()['exercises'] as List<dynamic>? ?? [];
                    for (var ex in exercises) {
                      final name = ex['name'] as String? ?? 'Ex';
                      final sets = ex['sets'] as List<dynamic>? ?? [];
                      for (var s in sets) {
                        final weight = (s['weight'] as num?)?.toDouble() ?? 0;
                        if (weight > (prs[name] ?? 0)) {
                          prs[name] = weight;
                        }
                      }
                    }
                  }
                  final topPrs = prs.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)); // Menor para maior (sort padrão)
                  // Inverte para pegar os maiores primeiro e pega top 5
                  final displayPrs = topPrs.reversed.take(5).toList();


                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // STATS CARDS
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildStatCard("Total de Treinos", "$totalWorkouts", cardColor, borderColor, textColor, subTextColor),
                            // Só mostra volume se não for Cardio puro
                            if (_selectedCategoryFilter != 1)
                              _buildStatCard("Volume Total", _formatVolume(totalVolume), cardColor, borderColor, textColor, subTextColor),
                            _buildStatCard("Tempo Total", _formatDuration(totalMinutes), cardColor, borderColor, textColor, subTextColor),
                            _buildStatCard("Calorias", "$totalCalories kcal", cardColor, borderColor, textColor, subTextColor),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // --- ABAS DE CATEGORIA (INTERATIVAS) ---
                        Container(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: borderColor)),
                          ),
                          child: Row(
                            children: [
                              _buildTabItem("Força", 0, primaryColor, subTextColor),
                              _buildTabItem("Cardio", 1, primaryColor, subTextColor),
                              _buildTabItem("Geral", 2, primaryColor, subTextColor),
                            ],
                          ),
                        ),
                        // ---------------------------------------

                        const SizedBox(height: 24),

                        // GRÁFICO PLACEHOLDER
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Frequência Semanal", style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text("${(totalWorkouts / 4).toStringAsFixed(1)} treinos (média)", style: TextStyle(color: subTextColor, fontSize: 14)),
                              const SizedBox(height: 20),
                              // Barras
                              SizedBox(
                                height: 150,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(7, (i) {
                                    // Alturas fictícias apenas para visual
                                    final h = [40, 80, 30, 100, 60, 20, 90][i];
                                    return _buildBar(h.toDouble(), ["Seg","Ter","Qua","Qui","Sex","Sáb","Dom"][i], primaryColor, subTextColor);
                                  }),
                                ),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // RECORDES PESSOAIS (Só mostra se tiver dados)
                        if (displayPrs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Melhores Cargas (PRs)", style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 16),
                                ...displayPrs.map((e) => Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(e.key, style: TextStyle(color: subTextColor)),
                                        Text("${e.value} kg", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Divider(color: borderColor, height: 1),
                                    const SizedBox(height: 12),
                                  ],
                                )).toList(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget do Card de Estatística
  Widget _buildStatCard(String label, String value, Color bg, Color border, Color text, Color subText) {
    // Ajusta largura dinamicamente: se for par de cards, divide por 2. Se sobrar (ímpares), ocupa tudo?
    // Vamos manter fixo 2 por linha para consistência
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: subText, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.epilogue(fontSize: 22, fontWeight: FontWeight.bold, color: text)),
        ],
      ),
    );
  }

  // Widget da Aba (Agora Interativo)
  Widget _buildTabItem(String text, int index, Color primary, Color subText) {
    final isActive = _selectedCategoryFilter == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategoryFilter = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isActive ? primary : Colors.transparent, width: 3)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isActive ? primary : subText,
                fontWeight: FontWeight.bold,
                fontSize: 14
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBar(double heightPercentage, String label, Color color, Color labelColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: heightPercentage,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: labelColor, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return "$minutes min";
    return "${(minutes / 60).toStringAsFixed(1)} h";
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) return "${(volume / 1000).toStringAsFixed(1)} ton";
    return "${volume.toInt()} kg";
  }
}