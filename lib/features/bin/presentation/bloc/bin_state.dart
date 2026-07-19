import 'package:equatable/equatable.dart';
import '../../domain/entities/bin_task_entity.dart';

abstract class BinState extends Equatable {
  const BinState();
  @override
  List<Object?> get props => [];
}

class BinInitial extends BinState {}
class BinLoading extends BinState {}
class BinLoaded extends BinState {
  final List<BinTaskEntity> tasks;
  const BinLoaded(this.tasks);
  @override
  List<Object?> get props => [tasks];
}
class BinError extends BinState {
  final String message;
  const BinError(this.message);
  @override
  List<Object?> get props => [message];
}
