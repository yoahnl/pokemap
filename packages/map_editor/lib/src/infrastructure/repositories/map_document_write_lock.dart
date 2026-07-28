import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';

final _mapDocumentWriteQueues = <String, Future<void>>{};

/// Serializes writers by canonical target both in-process and across processes.
///
/// The lock file lives outside the project so locking never creates authoring
/// artifacts that could be mistaken for project content.
Future<T> withMapDocumentWriteLock<T>(
  String mapPath,
  Future<T> Function(String canonicalMapPath) action,
) async {
  final canonicalMapPath = await canonicalMapDocumentPath(mapPath);
  final previous =
      _mapDocumentWriteQueues[canonicalMapPath] ?? Future<void>.value();
  final turn = Completer<void>();
  final tail = previous.then((_) => turn.future);
  _mapDocumentWriteQueues[canonicalMapPath] = tail;
  await previous;

  RandomAccessFile? handle;
  var locked = false;
  try {
    final pathHash = narrativeEventBytesFingerprint(
      utf8.encode(canonicalMapPath),
    ).substring(7, 31);
    final lockDirectory = Directory(
      p.join(Directory.systemTemp.path, 'pokemap-map-document-locks'),
    );
    await lockDirectory.create(recursive: true);
    final lockFile = File(p.join(lockDirectory.path, '$pathHash.lock'));
    handle = await lockFile.open(mode: FileMode.append);
    await handle.lock(FileLock.exclusive);
    locked = true;
    return await action(canonicalMapPath);
  } finally {
    if (handle != null) {
      if (locked) await handle.unlock();
      await handle.close();
    }
    turn.complete();
    if (identical(_mapDocumentWriteQueues[canonicalMapPath], tail)) {
      _mapDocumentWriteQueues.remove(canonicalMapPath);
    }
  }
}

Future<String> canonicalMapDocumentPath(String mapPath) async {
  final requested = File(p.normalize(p.absolute(mapPath)));
  // Following a symlink here would move the CAS boundary away from the path
  // the project manifest authorized.
  final requestedType = await FileSystemEntity.type(
    requested.path,
    followLinks: false,
  );
  if (requestedType == FileSystemEntityType.link) {
    throw EditorValidationException(
      'A map document cannot be persisted through a symbolic link: '
      '${requested.path}',
    );
  }
  if (requestedType == FileSystemEntityType.directory) {
    throw EditorValidationException(
      'A map document path resolves to a directory: ${requested.path}',
    );
  }

  if (requestedType == FileSystemEntityType.file) {
    return p.normalize(await requested.resolveSymbolicLinks());
  }

  await requested.parent.create(recursive: true);
  final canonicalParent = p.normalize(
    await requested.parent.resolveSymbolicLinks(),
  );
  return p.normalize(p.join(canonicalParent, p.basename(requested.path)));
}
