import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

final _projectWriteQueues = <String, Future<void>>{};

Future<T> withProjectManifestWriteLock<T>(
  String projectPath,
  Future<T> Function() action,
) async {
  final projectFile = File(projectPath);
  final qualifiedPath = p.normalize(
    await projectFile.exists()
        ? await projectFile.resolveSymbolicLinks()
        : projectFile.absolute.path,
  );
  final previous = _projectWriteQueues[qualifiedPath] ?? Future<void>.value();
  final turn = Completer<void>();
  final tail = previous.then((_) => turn.future);
  _projectWriteQueues[qualifiedPath] = tail;
  await previous;

  RandomAccessFile? handle;
  var locked = false;
  try {
    final pathHash = narrativeEventBytesFingerprint(
      utf8.encode(qualifiedPath),
    ).substring(7, 23);
    final lockFile = File(
      p.join(p.dirname(qualifiedPath), '.pokemap-project-$pathHash.lock'),
    );
    await lockFile.parent.create(recursive: true);
    handle = await lockFile.open(mode: FileMode.append);
    await handle.lock(FileLock.exclusive);
    locked = true;
    return await action();
  } finally {
    if (handle != null) {
      if (locked) await handle.unlock();
      await handle.close();
    }
    turn.complete();
    if (identical(_projectWriteQueues[qualifiedPath], tail)) {
      _projectWriteQueues.remove(qualifiedPath);
    }
  }
}
