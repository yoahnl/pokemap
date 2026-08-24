import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring_local.dart';

/// Writes one JSON line per project snapshot load, for diagnosis only.
///
/// Snapshot cost is invisible from inside the editor: a load either serves a
/// cached snapshot in milliseconds or rebuilds it from the whole project, and
/// nothing on screen says which happened. Benchmarks answer that question for
/// a scenario someone imagined; this answers it for the session the author
/// actually had.
///
/// Nothing is recorded unless [destinationVariable] names a file, so the
/// production path pays one map lookup at startup and nothing afterwards.
final class EditorSnapshotProfileRecorder {
  EditorSnapshotProfileRecorder._(this._destination);

  static const destinationVariable = 'POKEMAP_SNAPSHOT_PROFILE';

  static EditorSnapshotProfileRecorder? resolve({
    Map<String, String>? environment,
  }) {
    final destination =
        (environment ?? Platform.environment)[destinationVariable]?.trim();
    if (destination == null || destination.isEmpty) return null;
    return EditorSnapshotProfileRecorder._(File(destination));
  }

  final File _destination;
  Future<void> _pending = Future<void>.value();
  var _failed = false;

  ProjectSnapshotLoadProfileSink sinkFor(String session) {
    return (profile) => _append(<String, Object?>{
      'event': 'snapshot.load',
      'session': session,
      'cacheHit': profile.cacheHit,
      'totalUs': profile.totalMicroseconds,
      'initialReadUs': profile.initialReadMicroseconds,
      'decodeModelUs': profile.decodeModelMicroseconds,
      'secondObservationUs': profile.secondObservationMicroseconds,
      'fingerprintUs': profile.fingerprintMicroseconds,
      'projectionUs': profile.projectionMicroseconds,
      'resourceCount': profile.resourceCount,
      'resourceBytes': profile.resourceBytes,
      'cacheIdentityReads': profile.cacheIdentityReads,
      'assetBlobVerifications': profile.assetBlobVerifications,
      'revisionHashedBytes': profile.revisionHashedBytes,
    });
  }

  /// Records how often a mutation was projected onto the cached snapshot
  /// instead of forcing a reload. A load profile alone cannot show this: a
  /// successful adoption emits no load at all.
  void recordCacheCounters(ProjectSnapshotCache cache) {
    _append(<String, Object?>{
      'event': 'snapshot.cache',
      'hits': cache.hits,
      'misses': cache.misses,
      'canonicalHits': cache.canonicalHits,
      'sessionHits': cache.sessionHits,
      'invalidations': cache.invalidations,
      'adoptions': cache.adoptions,
      'adoptionRejections': cache.adoptionRejections,
      'identityReads': cache.identityReads,
    });
  }

  /// Completes once every line queued so far has reached the file.
  Future<void> flush() => _pending;

  /// Writes are queued rather than awaited by the caller: diagnosis must not
  /// add latency to the very path it measures. Chaining them keeps the file a
  /// faithful ordered log instead of interleaved fragments.
  void _append(Map<String, Object?> entry) {
    if (_failed) return;
    final line = '${jsonEncode(entry)}\n';
    _pending = _pending.then((_) async {
      if (_failed) return;
      try {
        await _destination.parent.create(recursive: true);
        await _destination.writeAsString(
          line,
          mode: FileMode.append,
          flush: true,
        );
      } on Object {
        // Diagnosis must never take the editor down with it. One failure is
        // enough to know the destination is unusable for this session.
        _failed = true;
      }
    });
  }
}
