import 'dart:async';
import 'dart:io';
import 'package:avelune_studio/features/project_creation/application/project_creation_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';

void main() {
  late Directory parent;
  setUp(() async {
    parent = await Directory.systemTemp.createTemp('creation-controller-');
  });
  tearDown(() async {
    await parent.delete(recursive: true);
  });
  ProjectCreationController configured(ProjectCreationPort port) =>
      ProjectCreationController(port)
        ..setName('Mon aventure')
        ..change(() {});

  test(
    'folder suggestion stops after manual input; validation preserves invalid input',
    () {
      final state = configured(const LocalProjectCreationService());
      expect(state.folderName, 'mon-aventure');
      state.setFolder('dossier-personnel');
      state.setName('Un autre nom');
      expect(state.folderName, 'dossier-personnel');
      state.setFolder('../interdit');
      expect(state.next(), isFalse);
      expect(state.step, 0);
      expect(state.folderName, '../interdit');
      expect(state.error, contains('dossier valide'));
      state.dispose();
    },
  );

  test(
    'accepted cancellation blocks writing and duplicate launch until cleanup',
    () async {
      final reached = Completer<void>(), release = Completer<void>();
      final state = configured(
        LocalProjectCreationService(
          checkpoint: (point, _) async {
            if (point == ProjectCreationCheckpoint.beforeReservation) {
              reached.complete();
              await release.future;
            }
          },
        ),
      )..parentPath = parent.path;
      final pending = state.create();
      await reached.future;
      expect(state.canCancel, isTrue);
      state.cancel();
      expect(state.running, isTrue);
      expect(await state.create(), isNull);
      state.change(() => state.tileSize = 48);
      expect(state.tileSize, 16);
      release.complete();
      expect(await pending, isNull);
      expect(state.receipt, isNull);
      expect(state.running, isFalse);
      expect(parent.listSync(), isEmpty);
      state.dispose();
    },
  );

  test(
    'writing is not cancellable; frozen request survives attempted changes',
    () async {
      final reached = Completer<void>(), release = Completer<void>();
      final state = configured(
        LocalProjectCreationService(
          checkpoint: (point, _) async {
            if (point == ProjectCreationCheckpoint.afterReservation) {
              reached.complete();
              await release.future;
            }
          },
        ),
      )..parentPath = parent.path;
      final pending = state.create();
      await reached.future;
      expect(state.canCancel, isFalse);
      state.cancel();
      state.change(() => state.name = 'Trop tard');
      expect(state.name, 'Mon aventure');
      release.complete();
      final receipt = await pending;
      expect(receipt?.manifest.name, 'Mon aventure');
      expect(state.receipt, same(receipt));
      state.dispose();
    },
  );
  test(
    'a confirmed destination cannot follow a rebound parent alias',
    () async {
      final first = await Directory('${parent.path}/first').create();
      final second = await Directory('${parent.path}/second').create();
      final alias = await Link('${parent.path}/chosen').create(first.path);
      final state = configured(const LocalProjectCreationService())
        ..parentPath = alias.path;
      await state.checkDestination();
      expect(
        state.destination,
        '${await first.resolveSymbolicLinks()}/mon-aventure',
      );
      await alias.delete();
      await alias.create(second.path);
      expect(await state.create(), isNull);
      expect(state.error, isNotNull);
      expect(state.receipt, isNull);
      expect(await first.list().isEmpty, isTrue);
      expect(await second.list().isEmpty, isTrue);
      state.dispose();
    },
  );
}
