import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../screens/cubit/navigation_cubit.dart';
import '../../../../l10n/app_localizations.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<NavigationCubit, int>(
      builder: (context, currentIndex) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(context, Icons.dashboard_outlined, Icons.dashboard_rounded, l10n.workspace, 0, currentIndex),
                  _buildNavItem(context, Icons.inbox_outlined, Icons.inbox_rounded, l10n.inbox, 1, currentIndex),
                  _buildNavItem(context, Icons.calendar_today_outlined, Icons.calendar_today_rounded, l10n.calendar, 2, currentIndex),
                  _buildNavItem(context, Icons.person_outline, Icons.person_rounded, l10n.profile, 3, currentIndex),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, IconData activeIcon, String label, int index, int currentIndex) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => context.read<NavigationCubit>().changeTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: isSelected ? AppColors.primary : AppColors.textSecondaryLight, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondaryLight, fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}