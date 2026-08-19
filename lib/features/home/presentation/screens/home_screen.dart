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

/// شاشات التابات الأربعة، معزولة بـ Widget لحالها حتى نقدر نحتفظ بحالة
/// خاصة فيها (شوفي _calendarInstanceId تحت) بدون ما نأثر على HomeScreen.
class _HomeTabs extends StatefulWidget {
  const _HomeTabs();

  @override
  State<_HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<_HomeTabs> {
  // ─── تاب الكالندر بيضل موجود بالذاكرة طول الوقت بسبب IndexedStack (حتى
  // لو المستخدم مش واقف فيه)، فلو ضاف تاسك من تاب تاني (مثلاً من
  // Workspace) ورجع عالكالندر، الكالندر كان عم يضل عارض نفس البيانات
  // القديمة يلي جابها أول مرة انفتح، لأنه ما في أي إشعار إله إنه في
  // بيانات جديدة. الحل: كل مرة يضغط المستخدم على تاب الكالندر، منبدّل
  // الـ key تبعو، وهيك Flutter بيهدم النسخة القديمة وينشئ نسخة جديدة
  // من الصفر (initState بيرجع يشتغل)، فبيعيد تحميل كل التاسكات طازة.
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
            // تاب الـ Inbox: مش شاشة خاصة، هو أصلاً TasksScreen عادية بس
            // بمشروع "وهمي" (pseudo-project) معرّفه kInboxProjectId وما
            // إلو workspace حقيقي — هيك منستفيد من كل منطق إضافة/عرض/حذف
            // التاسكات الجاهز بـ TasksScreen بدون ما نعيد كتابته من الصفر.
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