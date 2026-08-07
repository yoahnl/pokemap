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
