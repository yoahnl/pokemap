import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/resources/application/resource_image_import_draft.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/coordination/resource_workspace_import_workflow.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/platform/rendering/resource_image_content_verifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/resource_replacement_fixture.dart';

Future<ResourceImageImport?> _confirm(
  PickedResourceImage image,
  ProjectManifest project,
) async {
  final draft = ResourceImageImportDraft(
    image: image,
    tileWidth: project.settings.tileWidth,
    tileHeight: project.settings.tileHeight,
    existingNames: {for (final entry in project.tilesets) entry.name},
  );
  await draft.verify(verifyResourceImageContent);
  return draft.build();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an imported image stays a source with explicit next steps and is not offered as decor', () async {
    final host = await ResourceReplacementFixture.create();
    final picked = await host.candidate(name: 'Planche M2');
    final workflow = ResourceWorkspaceImportWorkflow(
      navigation: host.navigation,
      isActive: () => true,
    );
    expect(
      await workflow.importImage(picker: () async => picked, confirm: _confirm),
      isTrue,
    );
    final project = host.workspace.project!;
    final imported = project.tilesets.singleWhere(
      (item) => item.name == 'Planche M2',
    );
    expect(host.navigation.decor, isNull);
    expect(host.navigation.library.selectedIdentity, 'tileset:${imported.id}');
    expect(host.navigation.importedSource!.id, imported.id);
    expect(
      project.elements.where((element) => element.tilesetId == imported.id),
      isEmpty,
    );
    final state = MapWorkspaceEditingState();
    expect(
      state
          .paletteResourcesFor(project, project.maps.first.id, 'Décors')
          .map((item) => item.identity),
      isNot(contains('tileset:${imported.id}')),
    );
    host.navigation.edit(host.navigation.importedSource!);
    expect(host.navigation.decor?.tileset.id, imported.id);
  });

  test(
    'an import started from decor creation opens its native decor owner',
    () async {
      final host = await ResourceReplacementFixture.create();
      final picked = await host.candidate(name: 'Planche décor');
      final workflow = ResourceWorkspaceImportWorkflow(
        navigation: host.navigation,
        isActive: () => true,
      );
      expect(
        await workflow.importImage(
          picker: () async => picked,
          confirm: _confirm,
          intent: ResourceImportIntent.decor,
        ),
        isTrue,
      );
      final imported = host.workspace.project!.tilesets.singleWhere(
        (item) => item.name == 'Planche décor',
      );
      expect(host.navigation.decor?.tileset.id, imported.id);
      expect(host.navigation.importedSource, isNull);
    },
  );

  test('cancelling the image preflight publishes nothing', () async {
    final host = await ResourceReplacementFixture.create();
    final picked = await host.candidate();
    final before = await host.fixture.manifestFile.readAsBytes();
    final workflow = ResourceWorkspaceImportWorkflow(
      navigation: host.navigation,
      isActive: () => true,
    );
    expect(
      await workflow.importImage(
        picker: () async => picked,
        confirm: (_, _) async => null,
      ),
      isFalse,
    );
    expect(await host.fixture.manifestFile.readAsBytes(), before);
    expect(host.navigation.error, isNull);
    expect(host.navigation.importedSource, isNull);
    expect(host.navigation.managementDialogActive, isFalse);
  });

  test(
    'an invalid selected file is refused before any project change',
    () async {
      final host = await ResourceReplacementFixture.create();
      final before = await host.fixture.manifestFile.readAsBytes();
      final workflow = ResourceWorkspaceImportWorkflow(
        navigation: host.navigation,
        isActive: () => true,
      );
      var confirmations = 0;
      final imported = await workflow.importImage(
        picker: () async =>
            throw const ResourceFailure('Choisissez une image PNG valide.'),
        confirm: (_, _) async {
          confirmations++;
          return null;
        },
      );
      expect(imported, isFalse);
      expect(await host.fixture.manifestFile.readAsBytes(), before);
      expect(host.navigation.error, 'Choisissez une image PNG valide.');
      expect(confirmations, 0);
    },
  );

  test('preflight warns about an existing name and refuses an uneven grid while preserving input', () async {
    final host = await ResourceReplacementFixture.create();
    final picked = await host.candidate(width: 160, height: 64);
    final before = await host.fixture.manifestFile.readAsBytes();
    ResourceImageImportDraft? retained;
    final workflow = ResourceWorkspaceImportWorkflow(
      navigation: host.navigation,
      isActive: () => true,
    );
    await workflow.importImage(
      picker: () async => picked,
      confirm: (image, project) async {
        final draft = ResourceImageImportDraft(
          image: image,
          tileWidth: 48,
          tileHeight: 32,
          existingNames: {for (final entry in project.tilesets) entry.name},
        )..name = project.tilesets.single.name;
        retained = draft;
        await draft.verify(verifyResourceImageContent);
        return null;
      },
    );
    final draft = retained!;
    expect(draft.nameTaken, isTrue);
    expect(draft.restWidth, 16);
    expect(draft.build(), isNull);
    draft.width = '32';
    expect(draft.restWidth, 0);
    expect(draft.build(), isNotNull);
    expect(await host.fixture.manifestFile.readAsBytes(), before);
  });

  test('a PNG whose content does not decode cannot be imported and its source remains intact', () async {
    final host = await ResourceReplacementFixture.create();
    final picked = await host.candidate();
    final corrupted = Uint8List.fromList([
      ...picked.bytes.sublist(0, 60),
      ...List.filled(40, 7),
      ...picked.bytes.sublist(100),
    ]);
    final file = File(picked.path);
    await file.writeAsBytes(corrupted);
    final candidate = PickedResourceImage(
      picked.path,
      picked.name,
      corrupted,
      picked.width,
      picked.height,
    );
    final before = await host.fixture.manifestFile.readAsBytes();
    final workflow = ResourceWorkspaceImportWorkflow(
      navigation: host.navigation,
      isActive: () => true,
    );
    expect(
      await workflow.importImage(
        picker: () async => candidate,
        confirm: _confirm,
      ),
      isFalse,
    );
    expect(await host.fixture.manifestFile.readAsBytes(), before);
    expect(await file.readAsBytes(), corrupted);
    expect(host.navigation.importedSource, isNull);
  });

  test('one image management owner blocks a concurrent picker and a late closed result', () async {
    final host = await ResourceReplacementFixture.create();
    final picked = await host.candidate();
    var active = true, duplicatePicks = 0;
    final gate = Completer<PickedResourceImage?>();
    final workflow = ResourceWorkspaceImportWorkflow(
      navigation: host.navigation,
      isActive: () => active,
    );
    final importing = workflow.importImage(
      picker: () => gate.future,
      confirm: _confirm,
    );
    final other = ResourceWorkspaceImportWorkflow(
      navigation: host.navigation,
      isActive: () => true,
    );
    expect(
      await other.importImage(
        picker: () async {
          duplicatePicks++;
          return picked;
        },
        confirm: _confirm,
      ),
      isFalse,
    );
    active = false;
    gate.complete(picked);
    expect(await importing, isFalse);
    expect(duplicatePicks, 0);
    expect(host.navigation.managementDialogActive, isFalse);
    expect(host.workspace.project!.tilesets, hasLength(1));
  });

  test('a retained resource receipt blocks image picking before publication can repeat', () async {
    final host = await ResourceReplacementFixture.create();
    final before = await host.fixture.manifestFile.readAsBytes();
    final project = host.workspace.project!;
    final receipt = ResourceMutationReceipt(
      before: project,
      manifest: project,
      beforeRevision: 'a',
      revision: 'b',
      changedPaths: const ['project.json'],
    );
    host.navigation.pendingReceipt = receipt;
    var picks = 0;
    final workflow = ResourceWorkspaceImportWorkflow(
      navigation: host.navigation,
      isActive: () => true,
    );
    expect(
      await workflow.importImage(
        picker: () async {
          picks++;
          return null;
        },
        confirm: _confirm,
      ),
      isFalse,
    );
    expect(picks, 0);
    expect(host.navigation.pendingReceipt, same(receipt));
    expect(await host.fixture.manifestFile.readAsBytes(), before);
  });
}
