import 'dart:io';

typedef HubPackageOpenHandler = Future<void> Function(File package);

/// Platform services needed by the Hub composition root.
///
/// Game installation and validation stay in Dart. Native code is limited to
/// operating-system integration that Flutter cannot provide portably here.
abstract interface class HubPlatformAdapter {
  Future<void> attachPackageOpenHandler(HubPackageOpenHandler handler);

  Future<String?> pickPackage();

  Future<int> availableDiskBytes(Directory supportRoot);

  void dispose();
}

final class HubPackagePickerFailure implements Exception {
  const HubPackagePickerFailure({
    required this.code,
    required this.message,
    required this.recommendation,
    this.cause,
  });

  final String code;
  final String message;
  final String recommendation;
  final Object? cause;

  @override
  String toString() => cause == null ? message : '$message Cause: $cause';
}
