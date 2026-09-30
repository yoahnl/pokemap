import 'dart:async';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory parent;
  setUp(() async =>
      parent = await Directory.systemTemp.createTemp('creation_safety_'));
  tearDown(() async => parent.delete(recursive: true));
  ProjectCreationRequest request() => ProjectCreationRequest(
      name: 'Jeu', folderName: 'game', parentPath: parent.path);

  test('cancel while held before reservation creates no destination', () async {
    final held = Completer<void>();
    final release = Completer<void>();
    var cancelled = false;
    final phases = <ProjectCreationPhase>[];
    final service = LocalProjectCreationService(checkpoint: (point, _) async {
      if (point == ProjectCreationCheckpoint.beforeReservation) {
        held.complete();
        await release.future;
      }
    });
    final future = service.create(request(),
        onPhase: phases.add, isCancelled: () => cancelled);
    final expected =
        expectLater(future, throwsA(isA<ProjectCreationCancelled>()));
    await held.future;
    cancelled = true;
    release.complete();
    await expected;
    expect(await parent.list().toList(), isEmpty);
    expect(phases, isNot(contains(ProjectCreationPhase.writing)));
  });

  test('a late empty destination is preserved and never replaced', () async {
    final service =
        LocalProjectCreationService(checkpoint: (point, path) async {
      if (point == ProjectCreationCheckpoint.beforeReservation) {
        await Directory(path).create();
      }
    });
    await expectLater(
        service.create(request()), throwsA(isA<ProjectCreationException>()));
    final target = Directory(p.join(parent.path, 'game'));
    expect(await target.exists(), true);
    expect(await target.list().toList(), isEmpty);
  });

  test('confirmed canonical parent rebound before create is refused', () async {
    final chosen = await Directory(p.join(parent.path, 'chosen')).create();
    final other = await Directory.systemTemp.createTemp('other_creation_');
    addTearDown(() => other.delete(recursive: true));
    final input = ProjectCreationRequest(
        name: 'Jeu', folderName: 'game', parentPath: chosen.path);
    const service = LocalProjectCreationService();
    final confirmed = await service.validateDestination(input);
    await chosen.delete();
    await Link(chosen.path).create(other.path);
    await expectLater(
        service.create(input, expectedDestination: confirmed),
        throwsA(isA<ProjectCreationException>().having(
            (error) => error.code, 'code', 'project.destination_changed')));
    expect(await other.list().toList(), isEmpty);
  });

  test('exclusive OS reservation rejects collision after the final async check',
      () async {
    final target = Directory(p.join(parent.path, 'game'));
    await expectLater(
        const LocalProjectCreationService().create(request(), onPhase: (phase) {
          if (phase == ProjectCreationPhase.writing) {
            target.createSync();
            File(p.join(target.path, 'external')).writeAsBytesSync([1, 3, 5]);
          }
        }),
        throwsA(isA<ProjectCreationException>()));
    expect(
        await File(p.join(target.path, 'external')).readAsBytes(), [1, 3, 5]);
    expect((await target.list().toList()).length, 1);
  });

  test(
      'exclusive reservation refuses concurrent creators with no overwritten project',
      () async {
    final outcomes = await Future.wait([
      for (var index = 0; index < 2; index++)
        const LocalProjectCreationService()
            .create(request())
            .then<Object>((value) => value)
            .catchError((Object error) => error)
    ]);
    expect(outcomes.whereType<ProjectCreationReceipt>().length, 1);
    expect(outcomes.whereType<ProjectCreationException>().length, 1);
    expect(
        await File(p.join(parent.path, 'game', 'project.json')).exists(), true);
  });

  test(
      'after reservation failure identifies residual and keeps external data intact',
      () async {
    final service =
        LocalProjectCreationService(checkpoint: (point, path) async {
      if (point == ProjectCreationCheckpoint.afterReservation) {
        await File(p.join(path, 'external.txt')).writeAsString('keep');
        throw const FileSystemException('failure injected');
      }
    });
    await expectLater(
        service.create(request()),
        throwsA(isA<ProjectCreationException>().having(
            (error) => error.residualPath,
            'residualPath',
            p.join(await parent.resolveSymbolicLinks(), 'game'))));
    expect(
        await File(p.join(parent.path, 'game', 'external.txt')).readAsString(),
        'keep');
    expect(await File(p.join(parent.path, 'game', 'project.json')).exists(),
        false);
  });

  test(
      'canonical transaction failure after promotion never reports creation success',
      () async {
    final phases = <ProjectCreationPhase>[];
    final service = LocalProjectCreationService(faultInjector: (context) {
      if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted &&
          context.storageKey!.endsWith('.blob')) {
        throw const FileSystemException('write failure injected');
      }
    });
    await expectLater(
        service.create(request(), onPhase: phases.add),
        throwsA(isA<ProjectCreationException>()
            .having((error) => error.residualPath, 'residualPath', isNotNull)));
    expect(phases, isNot(contains(ProjectCreationPhase.completed)));
    expect(await File(p.join(parent.path, 'game', 'project.json')).exists(),
        false);
    expect(await Directory(p.join(parent.path, 'game', '.pokemap')).exists(),
        true);
    expect(
        await Directory(p.join(parent.path, 'game', 'assets', '.pokemap-store'))
            .list()
            .toList(),
        isEmpty);
  });

  test(
      'modification after transaction is preserved, rejected and never claimed successful',
      () async {
    final phases = <ProjectCreationPhase>[];
    String? modifiedPath;
    final service =
        LocalProjectCreationService(checkpoint: (point, path) async {
      if (point == ProjectCreationCheckpoint.afterApply) {
        modifiedPath =
            (await Directory(p.join(path, 'assets', '.pokemap-store'))
                    .list()
                    .toList())
                .single
                .path;
        await File(modifiedPath!).writeAsBytes([7, 8, 9]);
      }
    });
    await expectLater(service.create(request(), onPhase: phases.add),
        throwsA(isA<ProjectCreationException>()));
    expect(await File(modifiedPath!).readAsBytes(), [7, 8, 9]);
    expect(phases, isNot(contains(ProjectCreationPhase.completed)));
  });
}
