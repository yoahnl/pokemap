import 'dart:io';

/// Resolves the writable root the Hub owns on the host filesystem.
///
/// Injected rather than called directly so tests can point the whole app at a
/// temporary directory without touching the real application support folder.
abstract interface class SupportRootPort {
  Future<Directory> resolve();
}
