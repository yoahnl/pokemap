import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../dev/spatial_frame_recorder.dart';

void main() {
  late Directory run;
  setUp(() async {
    final temporary = await Directory.systemTemp.resolveSymbolicLinks();
    final parent = Directory(p.join(temporary, 'avelune-studio-captures'));
    if (await FileSystemEntity.type(parent.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw StateError('The test capture parent is a symlink.');
    }
    await parent.create();
    run = await parent.createTemp('guard-test-');
  });
  tearDown(() async {
    if (await run.exists()) await run.delete(recursive: true);
  });
  Future<void> mark(
    Directory directory, [
    String contents = 'avelune-studio-capture@1',
  ]) async {
    await File(p.join(directory.path, '.avelune-studio-capture-owner'))
        .writeAsString(contents);
  }

  test(
    'accepts one canonical task run under the real temporary capture root',
    () async {
      await mark(run);
      expect((await requireStudioCaptureRoot(run.path)).path, run.path);
    },
  );
  test('requires the exact generic ownership marker', () async {
    await expectLater(requireStudioCaptureRoot(run.path), throwsStateError);
    for (final contents in [
      'another-owner',
      'avelune-studio-capture@1\n',
      'avelune-studio-native-cs-capture@1',
    ]) {
      await mark(run, contents);
      await expectLater(requireStudioCaptureRoot(run.path), throwsStateError);
    }
  });
  test(
    'rejects an owned directory elsewhere, the shared parent and a nested run',
    () async {
      final outside = await Directory.systemTemp.createTemp(
        'outside-studio-capture-',
      );
      addTearDown(() => outside.delete(recursive: true));
      await mark(outside);
      await expectLater(
        requireStudioCaptureRoot(await outside.resolveSymbolicLinks()),
        throwsStateError,
      );
      await expectLater(
        requireStudioCaptureRoot(run.parent.path),
        throwsStateError,
      );
      final nested = await Directory(p.join(run.path, 'nested')).create();
      await mark(nested);
      await expectLater(
        requireStudioCaptureRoot(nested.path),
        throwsStateError,
      );
    },
  );
  test(
    'rejects a symlink run, a symlink marker and a noncanonical spelling',
    () async {
      await mark(run);
      final alias = Link(
        p.join(run.parent.path, '${p.basename(run.path)}-alias'),
      );
      await alias.create(run.path);
      addTearDown(alias.delete);
      await expectLater(requireStudioCaptureRoot(alias.path), throwsStateError);
      await expectLater(
        requireStudioCaptureRoot('${run.path}/../${p.basename(run.path)}'),
        throwsStateError,
      );
      final marker = File(p.join(run.path, '.avelune-studio-capture-owner'));
      await marker.delete();
      final externalMarker = File(p.join(run.path, 'marker-source'));
      await externalMarker.writeAsString('avelune-studio-capture@1');
      await Link(marker.path).create(externalMarker.path);
      await expectLater(requireStudioCaptureRoot(run.path), throwsStateError);
    },
  );
}
