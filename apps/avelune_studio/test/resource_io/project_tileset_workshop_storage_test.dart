import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../../packages/map_authoring/test/support/tileset_regrid_fixture.dart';

void main() {
  test(
    'Studio keeps draft references safe and rereads only the edited atlas',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'studio-tileset-grid-',
      );
      addTearDown(() => root.delete(recursive: true));
      final foreign = await writeTilesetRegridFixture(root);
      final sessions = LocalProjectSessionAdapter();
      final path = await root.resolveSymbolicLinks();
      final session = await sessions.open(path);
      addTearDown(() => sessions.close(session));
      final maps = LocalMapWorkspaceAdapter();
      final workspace = MapWorkspaceController(session, maps);
      addTearDown(workspace.dispose);
      await workspace.initialize();
      expect(workspace.error, isNull);
      var newDraftDuringCommit = true;
      var draftUsesAtlas = false;
      var interruptReread = false;
      final editor = LocalResourceAdapter(
        session: session,
        mapAdapter: maps,
        beforeTransactionPrecondition: () async {
          if (newDraftDuringCommit) draftUsesAtlas = true;
        },
        beforeReconciliation: () async {
          if (interruptReread) throw StateError('Lecture interrompue');
        },
      );
      addTearDown(editor.dispose);
      final library = await maps.readResourceLibrary(session);
      final prepared = await editor.prepareResourceIndexes(
        expectedSnapshotRevision: library.revision!,
      );
      final item = library.items.singleWhere(
        (item) => item.identity == 'tileset:sheet',
      );
      final head = File('$path/catalog/HEAD.json');
      final before = await head.readAsBytes();
      final image = File('$path/assets/sheet.png');
      final imageBefore = await image.readAsBytes();
      const blocked = 'Un brouillon utilise cette planche.';
      Future<ResourceMutationReceipt> save() => editor.saveTilesetGrid(
        item,
        tileSize: (width: 16, height: 16),
        expectedRevision: prepared.revision,
        validateBeforeApply: () => draftUsesAtlas ? blocked : null,
      );
      await expectLater(
        save(),
        throwsA(
          isA<ResourceFailure>().having(
            (error) => error.message,
            'message',
            blocked,
          ),
        ),
      );
      expect(await head.readAsBytes(), before);

      newDraftDuringCommit = false;
      draftUsesAtlas = false;
      interruptReread = true;
      final observed = <String>{};
      final outside = Zone.current;
      final receipt = await IOOverrides.runZoned(
        () async {
          try {
            await save();
          } on ResourceFailure catch (error) {
            return error.partialReceipt!;
          }
          throw StateError('La relecture attendue doit être interrompue.');
        },
        createFile: (path) {
          observed.add(path);
          return outside.run(() => File(path));
        },
      );
      expect(receipt.changedPaths, ['catalog/HEAD.json']);
      expect(
        observed.where(
          (path) => path.contains('/maps/') || path.endsWith('.png'),
        ),
        isEmpty,
      );
      expect(observed.where((path) => foreign.any(path.endsWith)), isEmpty);
      expect(await image.readAsBytes(), imageBefore);
      final committed = await head.readAsBytes();
      expect(committed, isNot(before));
      await editor.reconcileTilesetGrid(receipt);
      expect(await head.readAsBytes(), committed);

      final reopened = await sessions.open(path);
      addTearDown(() => sessions.close(reopened));
      final reopenedMaps = LocalMapWorkspaceAdapter();
      final reopenedWorkspace = MapWorkspaceController(reopened, reopenedMaps);
      addTearDown(reopenedWorkspace.dispose);
      await reopenedWorkspace.initialize();
      final after = await reopenedMaps.readResourcePreview(
        reopened,
        'tileset',
        item.id,
      );
      final source =
          after.tilesets.single.source as ProjectRegularAtlasTilesetSource;
      expect(
        (source.tileWidth, source.tileHeight, source.columns, source.rows),
        (16, 16, 4, 4),
      );
    },
  );
}
