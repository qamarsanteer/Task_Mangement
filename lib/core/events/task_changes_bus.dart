import 'dart:async';

/// بث بسيط (Event Bus) لإشعار أي TaskBloc حي بالذاكرة إنه لازم يعيد
/// تحميل قائمة تاسكاته، حتى لو التغيير صار من شاشة تانية كليًا وما
/// إلها أي علاقة بالـ Bloc/الشاشة يلي لازم تتحدّث.
///
/// ليش محتاجينه: تاب الـ Inbox (TasksScreen) محفوظ حي بالذاكرة طول
/// وقت التطبيق بسبب IndexedStack بـ HomeScreen (نفس المنطق المطبق
/// أصلاً على تاب الكالندر). لما المستخدم يفتح BinScreen (يلي بينفتح
/// من تاب الإعدادات، بعيد كليًا عن التاب/الـ TaskBloc تبع الـ Inbox)
/// ويستعيد تاسك، بيتحدّث بس BinBloc — ما في أي شي كان عم يخبر TaskBloc
/// القديم/الحي إنه لازم يعيد الجلب، فالتاسك المسترجع كان عم يضل غير
/// ظاهر بالـ Inbox لحد ما تعمل hot restart أو تسكّر وتفتح التطبيق.
class TaskChangesBus {
  final _controller = StreamController<String>.broadcast();

  /// بيبعت الـ projectId يلي تغيّر (مثلاً: استرجاع تاسك من السلة، أو
  /// نقل تاسك لمشروع). أي شاشة/Bloc مهتم بنفس المشروع هيدا لازم
  /// يعيد تحميل قائمته.
  Stream<String> get onProjectChanged => _controller.stream;

  void notifyProjectChanged(String projectId) {
    if (!_controller.isClosed) {
      _controller.add(projectId);
    }
  }

  void dispose() => _controller.close();
}