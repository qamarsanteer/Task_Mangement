import 'package:equatable/equatable.dart';
import '../../../task/domain/entities/deleted_task_entry.dart';

abstract class BinState extends Equatable {
  const BinState();
  @override
  List<Object?> get props => [];
}

class BinInitial extends BinState {}

class BinLoading extends BinState {}

class BinLoaded extends BinState {
  final List<DeletedTaskEntry> entries;
  // true وقت ما في عملية استرجاع/حذف نهائي شغالة، حتى نعطّل الأزرار
  // بالواجهة وما يصير دبل-تاب من المستخدم لنفس العنصر.
  final bool isMutating;

  const BinLoaded({required this.entries, this.isMutating = false});

  @override
  List<Object?> get props => [entries, isMutating];
}

class BinError extends BinState {
  final String message;
  // منحتفظ بآخر قائمة كانت معروضة حتى لو صار خطأ (نفس منطق TaskError)،
  // حتى ما تختفي القائمة كاملة من الشاشة بسبب فشل عملية وحدة.
  final List<DeletedTaskEntry> entries;

  const BinError({required this.message, required this.entries});

  @override
  List<Object?> get props => [message, entries];
}
