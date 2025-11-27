// lib/presentation/widgets/navigation/bottom_nav_bar.dart - ATUALIZADO (Treinos no lugar de Explorar)

import 'dart:ui';
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onAddTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF13EC6D);

    final backgroundColor = theme.scaffoldBackgroundColor.withValues(alpha: 0.8);
    final inactiveColor = theme.hintColor.withValues(alpha: 0.6);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Item 0: Feed
              _NavItem(
                icon: Icons.home_rounded,
                label: "Feed",
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
                activeColor: primaryColor,
                inactiveColor: inactiveColor,
              ),

              // Item 1: Treinos (SUBSTITUIU O EXPLORAR)
              _NavItem(
                icon: Icons.fitness_center_rounded, // Ícone de Haltere
                label: "Treinos", // Texto alterado
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
                activeColor: primaryColor,
                inactiveColor: inactiveColor,
              ),

              // Botão Central: Adicionar (+)
              GestureDetector(
                onTap: onAddTap,
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ),
              ),

              // Item 2: Progresso (Agora é um placeholder para gráficos futuros)
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: "Progresso",
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
                activeColor: primaryColor,
                inactiveColor: inactiveColor,
              ),

              // Item 3: Perfil
              _NavItem(
                icon: Icons.person_rounded,
                label: "Perfil",
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
                activeColor: primaryColor,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar (MANTIDO IGUAL)
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}