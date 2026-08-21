import 'dart:async';

class TaskChangesBus {
  final _controller = StreamController<String>.broadcast();

  Stream<String> get onProjectChanged => _controller.stream;

  void notifyProjectChanged(String projectId) {
    if (!_controller.isClosed) {
      _controller.add(projectId);
    }
  }

  void dispose() => _controller.close();
}