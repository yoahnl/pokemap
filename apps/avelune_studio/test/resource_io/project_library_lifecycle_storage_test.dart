import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import 'working_catalog_classification_fixture.dart';

void main() {
  test('editing, duplicating and withdrawing library definitions are scoped', () async {
    final fixture = await ClassificationFixture.create(unrelated: 300);
    addTearDown(fixture.dispose);
    await fixture.openWorkspace();
    final maps = fixture.maps;
    final editor = fixture.resources;
    final session = fixture.session;
    final library = await maps.readResourceLibrary(session);
    var revision = library.revision!;
    revision = (await editor.prepareResourceIndexes(
      expectedSnapshotRevision: revision,
    )).revision;
    final mapFile = File('${fixture.root.path}/maps/jardin.json');
    final savedMap = await mapFile.readAsBytes();
    final draft = fixture.workspace.active!;
    draft.commit(draft.current.copyWith(name: 'Brouillon à conserver'));
    final tree = library.items.singleWhere(
      (item) => item.identity == 'element:arbre',
    );
    await expectLater(
      editor.prepareLibraryDeletion(tree, expectedRevision: revision),
      throwsA(
        isA<ResourceFailure>().having(
          (failure) => failure.message,
          'consumer name',
          contains(
            fixture.workspace.project!.maps
                .firstWhere((map) => map.id == 'jardin')
                .name,
          ),
        ),
      ),
    );
    final sourceFile = File('${fixture.root.path}/pilote.glb');
    await sourceFile.writeAsBytes(triangleGlb());
    final imported = await editor.importResource(
      PickedProjectLibraryFile(path: sourceFile.path, name: 'Pilote'),
      name: 'Pilote',
      tileSize: null,
      expectedRevision: revision,
    );
    fixture.accept(imported.receipt);
    final configured = await editor.mutate('model3d.configure', {
      'modelId': imported.item.id,
      'castsShadowsByDefault': true,
    });
    fixture.accept(configured);
    revision = (await maps.readResourceLibrary(session)).revision!;
    final reads = <String>{};
    final outside = Zone.current;
    await IOOverrides.runZoned(
      () async {
        final edited = await editor.modifyLibraryResource(
          imported.item,
          description: 'Décor de test',
          placementContext: ResourcePlacementContext.exterior,
          expectedRevision: revision,
        );
        fixture.accept(edited.receipt);
        expect(edited.item.description, 'Décor de test');
        final copied = await editor.duplicateLibraryResource(
          edited.item,
          name: 'Pilote dupliqué',
          expectedRevision: edited.receipt.revision,
        );
        fixture.accept(copied.receipt);
        expect(copied.item.id, isNot(imported.item.id));
        expect(copied.item.description, 'Décor de test');
        expect(copied.item.placementContext, ResourcePlacementContext.exterior);
        final sourceModel = await maps.readResourcePreview(
          session,
          'model3d',
          imported.item.id,
        );
        final copiedModel = await maps.readResourcePreview(
          session,
          'model3d',
          copied.item.id,
        );
        expect(copiedModel.models3d.single.castsShadowsByDefault, isTrue);
        expect(
          copiedModel.models3d.single.inspection,
          sourceModel.models3d.single.inspection,
        );
        expect(
          editor.libraryDraftUses(copied.item, [
            {'modelId': copied.item.id},
          ]),
          isTrue,
        );
        await fixture.workspace.ensureResourceKind('model3d');
        expect(
          fixture.workspace.visualProject!.models3d.map((model) => model.id),
          contains(copied.item.id),
        );

        final removal = await editor.prepareLibraryDeletion(
          copied.item,
          expectedRevision: copied.receipt.revision,
        );
        expect(removal.impact['usageCount'], 0);
        await expectLater(
          editor.applyPrepared(removal),
          throwsA(isA<ResourceFailure>()),
        );
        final receipt = await editor.applyPrepared(
          removal,
          confirmDestructive: true,
        );
        fixture.accept(receipt);
        expect(
          fixture.workspace.visualProject!.models3d.map((model) => model.id),
          isNot(contains(copied.item.id)),
        );
        expect(
          receipt.changedPaths.where((path) => path.startsWith('assets/')),
          isEmpty,
        );
        revision = receipt.revision;
        expect(
          await File(
            '${fixture.root.path}/${copiedModel.models3d.single.relativePath}',
          ).readAsBytes(),
          triangleGlb(),
        );
        final tile = library.items.firstWhere((item) => item.kind == 'tileset');
        final tileCopy = await editor.duplicateLibraryResource(
          tile,
          name: 'Planche dupliquée',
          expectedRevision: revision,
        );
        fixture.accept(tileCopy.receipt);
        expect(tileCopy.item.id, isNot(tile.id));
        revision = tileCopy.receipt.revision;
      },
      createFile: (path) {
        reads.add(path);
        return outside.run(() => File(path));
      },
    );
    expect(reads.where((path) => path.contains('/maps/')), isEmpty);
    expect(draft.current.name, 'Brouillon à conserver');
    expect(fixture.workspace.active, same(draft));
    expect(await mapFile.readAsBytes(), savedMap);
    await fixture.reopen();
    final reopened = await fixture.maps.readResourceLibrary(fixture.session);
    expect(reopened.revision, revision);
    expect(
      reopened.items.where((item) => item.name == 'Pilote dupliqué'),
      isEmpty,
    );
    final original = reopened.items.singleWhere(
      (item) => item.identity == imported.item.identity,
    );
    expect(original.description, 'Décor de test');
    expect(original.placementContext, ResourcePlacementContext.exterior);
    expect(reopened.items.length, library.items.length + 2);
  });
}
