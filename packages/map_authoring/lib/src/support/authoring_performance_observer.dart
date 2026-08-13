final class AuthoringPerformanceSpanName {
  const AuthoringPerformanceSpanName._();

  static const snapshot = 'snapshot';
  static const plan = 'plan';
  static const apply = 'apply';
  static const saveQueue = 'save.queue';
  static const saveEncode = 'save.encode';
}

final class AuthoringPerformanceCounterName {
  const AuthoringPerformanceCounterName._();

  static const filesystemRead = 'filesystem.read';
  static const filesystemWrite = 'filesystem.write';
  static const filesystemMetadata = 'filesystem.metadata';
  static const jsonEncode = 'json.encode';
  static const jsonDecode = 'json.decode';
  static const base64Encode = 'base64.encode';
  static const base64Decode = 'base64.decode';
}

abstract interface class AuthoringPerformanceSpan {
  void finish();
}

abstract interface class AuthoringPerformanceObserver {
  AuthoringPerformanceSpan? startSpan(String name);

  void incrementCounter(String name, {int by = 1});
}
