import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../project/domain/entities/project_entity.dart';
import '../../../task/presentation/screens/tasks_screen.dart';
import '../../../workspace/presentation/screens/workspaces_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import 'cubit/navigation_cubit.dart';
import '../../../../core/constants/inbox_constants.dart';
import '../../../../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavigationCubit(),
      child: const Scaffold(
        body: _HomeTabs(),
        bottomNavigationBar: BottomNavBar(),
      ),
    );
  }
}

class _HomeTabs extends StatefulWidget {
  const _HomeTabs();

  @override
  State<_HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<_HomeTabs> {
  int _calendarInstanceId = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<NavigationCubit, int>(
      listenWhen: (previous, current) => current == 2,
      listener: (context, currentIndex) {
        setState(() => _calendarInstanceId++);
      },
      builder: (context, currentIndex) {
        return IndexedStack(
          index: currentIndex,
          children: [
            const WorkspacesScreen(),
            TasksScreen(
              project: ProjectEntity(id: kInboxProjectId, name: l10n.inbox, workspaceId: ''),
              workspaceName: l10n.inbox,
            ),
            CalendarScreen(key: ValueKey(_calendarInstanceId)),
            const ProfileScreen(),
          ],
        );
      },
    );
  }
}