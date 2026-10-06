import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_image_import.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:avelune_studio/presentation/features/characters/character_studio_dedicated_only_panel.dart';

import '../support/m2_ui_fixture.dart';
import '../support/map_tool_menu.dart';
import '../support/resource_family_gestures.dart';

void main() {
  testWidgets('a dedicated three-pose strip imports and its timing reopens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(() => M2UiFixture.create(tester)))!;
    addTearDown(fixture.dispose);
    final strip = await tester.runAsync(() async {
      final picture = image.Image(width: 96, height: 32, numChannels: 4);
      for (var i = 0; i < 3; i++) {
        image.fillRect(
          picture,
          x1: i * 32,
          y1: 0,
          x2: i * 32 + 31,
          y2: 31,
          color: image.ColorRgba8(40 + i * 60, 80, 190, 255),
        );
      }
      final bytes = Uint8List.fromList(image.encodePng(picture));
      final file = File('${fixture.directory.path}/marche-dediee.png');
      await file.writeAsBytes(bytes);
      return PickedResourceImage(file.path, 'Marche dédiée', bytes, 96, 32);
    });
    final atlas = await tester.runAsync(() async {
      final picture = image.Image(width: 256, height: 256, numChannels: 4);
      image.fill(picture, color: image.ColorRgba8(70, 110, 150, 255));
      final bytes = Uint8List.fromList(image.encodePng(picture));
      final file = File('${fixture.directory.path}/planche-base.png');
      await file.writeAsBytes(bytes);
      return PickedResourceImage(file.path, 'Planche de base', bytes, 256, 256);
    });
    var picks = 0;
    await tester.pumpWidget(
      fixture.app(
        tester,
        imagePicker: () async => ++picks == 1 ? atlas : strip,
      ),
    );
    await pumpIo(tester);
    await chooseMapExtraTool(tester, 'Gérer les ressources');
    await pumpIo(tester);
    await selectResourceFamily(tester, ResourceLibraryFamily.images);
    await tester.tap(find.text('Importer une image'));
    await pumpIo(tester);
    await tester.tap(find.text('Importer').last);
    await pumpIo(tester);
    await tester.tap(find.text('Retour aux ressources'));
    await pumpIo(tester);
    await openResourceCharacters(tester);
    await tester.tap(find.text('Nouveau personnage'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'Agent');
    await tester.tap(find.text('Créer'));
    await pumpIo(tester);
    final navigation = tester
        .widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane))
        .navigation;
    await tester.tap(find.text('Découper automatiquement'));
    await tester.pump();
    expect(
      navigation.characters.selectedDraft!.changedClips.toList(),
      hasLength(4),
    );
    await tester.tap(find.text('Importer une animation dédiée'));
    await tester.pump();
    await tester.tap(find.text('Enregistrer puis importer'));
    for (var attempt = 0; attempt < 120 && picks < 2; attempt++) {
      await pumpIo(tester, frames: 1);
    }
    expect(navigation.characters.error, isNull);
    expect(navigation.characters.selectedDraft!.dirty, isFalse);
    expect(picks, 2);
    expect(find.text('Importer'), findsWidgets);
    await tester.tap(find.text('Importer').last);
    await pumpIo(tester);
    final saved = navigation.workspace.project!;
    final character = saved.characters.firstWhere(
      (entry) => entry.name == 'Agent',
    );
    final clip = character.animations.singleWhere(
      (entry) =>
          entry.state == CharacterAnimationState.walk &&
          entry.direction == EntityFacing.south,
    );
    expect(clip.sourceAssetId, isNotNull);
    expect(clip.frames.map((entry) => entry.source.x), [0, 32, 64]);
    expect(clip.frames.every((entry) => entry.source.width == 32), isTrue);
    expect(
      character.animations
          .singleWhere(
            (entry) =>
                entry.state == CharacterAnimationState.walk &&
                entry.direction == EntityFacing.north,
          )
          .sourceAssetId,
      isNull,
    );
    await fixture.capture(tester, 'character-studio-dedicated');
    await tester.tap(find.text('150 ms').first);
    await tester.pump();
    await tester.tap(find.text('300 ms').last);
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await pumpIo(tester);
    final reopened = await tester.runAsync(
      () => LocalMapWorkspaceAdapter().loadProject(fixture.session),
    );
    final persisted = reopened!.characters
        .firstWhere((entry) => entry.id == character.id)
        .animations
        .singleWhere(
          (entry) =>
              entry.state == CharacterAnimationState.walk &&
              entry.direction == EntityFacing.south,
        );
    expect(persisted.sourceAssetId, clip.sourceAssetId);
    expect(persisted.frames.first.durationMs, 300);
    EntityFacing? requestedDirection;
    Navigator.of(tester.element(find.byType(ResourceWorkspacePane))).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: CharacterStudioDedicatedOnlyPanel(
            hasAtlas: false,
            draft: navigation.characters.selectedDraft!,
            controller: navigation.characters,
            visuals: fixture.visuals!,
            onImport: (_, direction) => requestedDirection = direction,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Haut').last);
    await tester.pump();
    await tester.tap(find.text('Importer une animation dédiée'));
    expect(requestedDirection, EntityFacing.north);
    await tester.pumpWidget(const SizedBox());
    await pumpIo(tester);
  });
}
