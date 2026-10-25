import 'dart:developer';

Future<T> traceAuthoringPhase<T>(
  String name,
  Future<T> Function() operation, {
  Map<String, Object?>? arguments,
}) async {
  final task = TimelineTask()..start(name, arguments: arguments);
  try {
    return await operation();
  } finally {
    task.finish();
  }
}

T traceAuthoringSync<T>(
  String name,
  T Function() operation, {
  Map<String, Object?>? arguments,
}) => Timeline.timeSync(name, operation, arguments: arguments);
