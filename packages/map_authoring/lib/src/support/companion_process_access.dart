import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

void initializeCompanionProcessAccess() {
  final libraryPath = Platform.environment['AVELUNE_PROJECT_ACCESS_LIBRARY'];
  final watchdogPath =
      Platform.environment['AVELUNE_PARENT_WATCHDOG_LIBRARY'] ?? libraryPath;
  final owner = int.tryParse(Platform.environment['AVELUNE_OWNER_PID'] ?? '');
  if (watchdogPath != null && owner != null) {
    if (!File(watchdogPath).isAbsolute ||
        DynamicLibrary.open(watchdogPath)
                .lookupFunction<Int32 Function(Int32), int Function(int)>(
                    'avelune_watch_parent')(owner) !=
            0) {
      throw StateError('The companion owner is unavailable.');
    }
  }
  if (libraryPath == null) return;
  if (!Platform.isMacOS || !File(libraryPath).isAbsolute) {
    throw const FormatException('Invalid companion access library.');
  }
  final library = DynamicLibrary.open(libraryPath);
  final grant = library.lookupFunction<
      Int32 Function(Pointer<Uint8>, Pointer<Uint8>),
      int Function(Pointer<Uint8>, Pointer<Uint8>)>('avelune_access_grant');
  final revoke = library.lookupFunction<Void Function(), void Function()>(
    'avelune_access_revoke_all',
  );
  final allocate = DynamicLibrary.process().lookupFunction<
      Pointer<Void> Function(IntPtr), Pointer<Void> Function(int)>('malloc');
  final release = DynamicLibrary.process().lookupFunction<
      Void Function(Pointer<Void>), void Function(Pointer<Void>)>('free');
  Pointer<Uint8> string(String value) {
    if (value.contains('\u0000')) {
      throw const FormatException('Invalid access grant.');
    }
    final bytes = utf8.encode(value);
    final pointer = allocate(bytes.length + 1).cast<Uint8>();
    if (pointer == nullptr) throw StateError('Access grant allocation failed.');
    pointer.asTypedList(bytes.length + 1)
      ..setAll(0, bytes)
      ..[bytes.length] = 0;
    return pointer;
  }

  try {
    final grants = jsonDecode(
        Platform.environment['AVELUNE_PROJECT_ACCESS_GRANTS'] ?? '[]');
    if (grants is! List || grants.length > 1) {
      throw const FormatException('Invalid access grants.');
    }
    for (final value in grants) {
      if (value is! Map ||
          value['root'] is! String ||
          value['bookmark'] is! String ||
          (value['bookmark'] as String).length > 2 * 1024 * 1024) {
        throw const FormatException('Invalid access grant.');
      }
      final root = string(value['root'] as String);
      final bookmark = string(value['bookmark'] as String);
      try {
        if (grant(root, bookmark) != 0) {
          throw StateError('Project access transfer failed.');
        }
      } finally {
        release(root.cast());
        release(bookmark.cast());
      }
    }
  } on Object {
    revoke();
    rethrow;
  }
}
