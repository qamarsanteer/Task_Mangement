import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../workspace/presentation/screens/workspaces_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import 'cubit/navigation_cubit.dart';
import '../../../../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (_) => NavigationCubit(),
      child: Scaffold(
        body: BlocBuilder<NavigationCubit, int>(
          builder: (context, currentIndex) {
            return IndexedStack(
              index: currentIndex,
              children: [
                const WorkspacesScreen(),
                _PlaceholderScreen(title: l10n.inbox, icon: Icons.inbox),
                _PlaceholderScreen(title: l10n.calendar, icon: Icons.calendar_today),
                const ProfileScreen(),
              ],
            );
          },
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white24 : Colors.black12)),
        ],
      ),
    );
  }
}