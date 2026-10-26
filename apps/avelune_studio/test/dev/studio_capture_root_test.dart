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
  test('accepts only the owned captures child of one canonical QA task', () async {
    final captures = await _ownedQaCaptures();
    await expectLater(
      requireStudioCaptureRoot(captures.path),
      throwsStateError,
    );
    await mark(captures);
    expect((await requireStudioCaptureRoot(captures.path)).path, captures.path);
    await mark(captures, 'avelune-studio-capture@1\n');
    await expectLater(
      requireStudioCaptureRoot(captures.path),
      throwsStateError,
    );
    await mark(captures);
    await expectLater(
      requireStudioCaptureRoot(captures.parent.path),
      throwsStateError,
    );
    final nested = await Directory(p.join(captures.path, 'nested')).create();
    await mark(nested);
    await expectLater(requireStudioCaptureRoot(nested.path), throwsStateError);
    await expectLater(
      requireStudioCaptureRoot(
        '${captures.parent.path}/../${p.basename(captures.parent.path)}/captures',
      ),
      throwsStateError,
    );
  }, skip: !Platform.isMacOS);
  test('accepts the sandbox QA root and rejects task aliases', () async {
    final captures = await _ownedQaCaptures(sandboxed: true);
    await mark(captures);
    expect((await requireStudioCaptureRoot(captures.path)).path, captures.path);
    final alias = Link(
      p.join(
        captures.parent.parent.path,
        '${p.basename(captures.parent.path)}-sandbox-guard-alias-$pid',
      ),
    );
    await alias.create(captures.parent.path);
    addTearDown(alias.delete);
    await expectLater(
      requireStudioCaptureRoot(p.join(alias.path, 'captures')),
      throwsStateError,
    );
    await mark(captures, 'avelune-studio-capture@1\n');
    await expectLater(
      requireStudioCaptureRoot(captures.path),
      throwsStateError,
    );
    await expectLater(
      requireStudioCaptureRoot(
        '${captures.parent.path}/../${p.basename(captures.parent.path)}/captures',
      ),
      throwsStateError,
    );
  }, skip: !Platform.isMacOS);
  test(
    'canonical QA captures reject a symlink task, root and marker',
    () async {
      final captures = await _ownedQaCaptures();
      await mark(captures);
      final alias = Link(
        p.join(
          captures.parent.parent.path,
          '${p.basename(captures.parent.path)}-capture-guard-alias-$pid',
        ),
      );
      await alias.create(captures.parent.path);
      addTearDown(alias.delete);
      await expectLater(
        requireStudioCaptureRoot(p.join(alias.path, 'captures')),
        throwsStateError,
      );
      final target = await captures.parent.createTemp('capture-guard-target-');
      addTearDown(() => target.delete(recursive: true));
      final marker = File(
        p.join(captures.path, '.avelune-studio-capture-owner'),
      );
      await marker.delete();
      final source = File(p.join(target.path, 'marker'));
      await source.writeAsString('avelune-studio-capture@1');
      await Link(marker.path).create(source.path);
      await expectLater(
        requireStudioCaptureRoot(captures.path),
        throwsStateError,
      );
      await Link(marker.path).delete();
      await captures.delete();
      await mark(target);
      await Link(captures.path).create(target.path);
      await expectLater(
        requireStudioCaptureRoot(captures.path),
        throwsStateError,
      );
      await Link(captures.path).delete();
    },
    skip: !Platform.isMacOS,
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

Future<Directory> _ownedQaCaptures({bool sandboxed = false}) async {
  final task = Directory(
    sandboxed
        ? '/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Library/Caches/AveluneQA/studio-project-lifecycle'
        : '/Users/karim/Library/Caches/AveluneQA/studio-project-lifecycle',
  );
  await task.create(recursive: true);
  final captures = Directory(p.join(task.path, 'captures'));
  if (await FileSystemEntity.type(captures.path, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw StateError('The capture guard fixture cannot reuse an active root.');
  }
  await captures.create();
  addTearDown(() async {
    final type = await FileSystemEntity.type(captures.path, followLinks: false);
    if (type == FileSystemEntityType.link) {
      await Link(captures.path).delete();
    } else if (type == FileSystemEntityType.directory) {
      await captures.delete(recursive: true);
    }
  });
  return captures;
}
