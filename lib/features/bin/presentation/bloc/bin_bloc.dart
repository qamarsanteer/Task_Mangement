import 'package:flutter_bloc/flutter_bloc.dart';
import 'bin_event.dart';
import 'bin_state.dart';

class BinBloc extends Bloc<BinEvent, BinState> {
  BinBloc() : super(BinInitial()) {
    on<LoadDeletedTasks>(_onLoadDeletedTasks);
    on<RestoreTask>(_onRestoreTask);
    on<DeleteTaskForever>(_onDeleteTaskForever);
  }

  Future<void> _onLoadDeletedTasks(LoadDeletedTasks event, Emitter<BinState> emit) async {
    emit(BinLoading());
    // TODO: Fetch from API
    emit(const BinLoaded([]));
  }

  Future<void> _onRestoreTask(RestoreTask event, Emitter<BinState> emit) async {
    // TODO: Call API to restore
  }

  Future<void> _onDeleteTaskForever(DeleteTaskForever event, Emitter<BinState> emit) async {
    // TODO: Call API to delete permanently
  }
}
