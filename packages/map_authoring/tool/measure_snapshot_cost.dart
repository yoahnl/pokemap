// Measures what one canonical project snapshot actually costs.
//
// Every canonical mutation re-reads and re-decodes the project from disk, and
// a single editor gesture needs several snapshots. This reports the real
// numbers for a given project so the cache/lazy-loading work is aimed at a
// measured bottleneck instead of a guess.
//
//   dart tool/measure_snapshot_cost.dart '/path/to/a/pokemap/project'
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';

const int _runs = 5;

String _ms(int microseconds) =>
    (microseconds / 1000).toStringAsFixed(1).padLeft(7);

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: dart tool/measure_snapshot_cost.dart <projectRoot>');
    exitCode = 64;
    return;
  }
  final root = args.first;

  // Same composition the editor uses to open a project.
  const fileReader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: <String>[root],
    fileReader: fileReader,
  );
  final handles = WorkspaceHandleStore();
  final profiles = <ProjectSnapshotLoadProfile>[];
  final snapshots = ProjectSnapshotLoader(
    handles: handles,
    profileSink: profiles.add,
  );
  final api = AuthoringReadApi(
    openService: ProjectOpenService(
      policy: policy,
      fileReader: fileReader,
      handles: handles,
    ),
    snapshotLoader: snapshots,
  );

  final opened = await api.open(root);
  final projectHandle = ProjectHandle(opened['projectHandle']! as String);
  final workspaceHandle = WorkspaceHandle(opened['workspaceHandle']! as String);

  try {
    for (var run = 0; run < _runs; run += 1) {
      await snapshots.load(projectHandle);
    }
  } finally {
    await api.close(workspaceHandle);
  }

  if (profiles.isEmpty) {
    stderr.writeln('No profile emitted.');
    exitCode = 1;
    return;
  }

  final totals = profiles.map((p) => p.totalMicroseconds).toList()..sort();
  final median = totals[totals.length ~/ 2];
  final last = profiles.last;

  stdout
    ..writeln('Project : $root')
    ..writeln('Snapshot: ${last.resourceCount} resources, '
        '${(last.resourceBytes / 1024 / 1024).toStringAsFixed(1)} MB')
    ..writeln('Runs    : ${profiles.length}')
    ..writeln('')
    ..writeln('Median total       ${_ms(median)} ms')
    ..writeln('  read from disk   ${_ms(last.initialReadMicroseconds)} ms')
    ..writeln('  decode model     ${_ms(last.decodeModelMicroseconds)} ms')
    ..writeln('  second read      ${_ms(last.secondObservationMicroseconds)} ms')
    ..writeln('  fingerprint      ${_ms(last.fingerprintMicroseconds)} ms')
    ..writeln('  projection       ${_ms(last.projectionMicroseconds)} ms')
    ..writeln('')
    ..writeln('One paint/erase plans then applies: >= 2 snapshots '
        '=> ~${(median * 2 / 1000).toStringAsFixed(0)} ms of snapshot work.')
    ..writeln('Adding a layer opens, plans, applies, reopens: 4 snapshots '
        '=> ~${(median * 4 / 1000).toStringAsFixed(0)} ms.');
}
