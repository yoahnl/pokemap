import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:image/image.dart' as image;
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/characters/character_studio_page.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:avelune_studio/presentation/features/resources/resource_image_import.dart';
import 'package:avelune_studio/platform/rendering/studio_character_thumbnail.dart';

import '../support/m2_ui_fixture.dart';
import '../support/map_tool_menu.dart';
import '../support/resource_family_gestures.dart';

void main() {
  testWidgets(
    'Character Studio edits a clip through the real workspace and reopens it',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(
        () => M2UiFixture.create(tester),
      ))!;
      addTearDown(fixture.dispose);
      await tester.pumpWidget(fixture.app(tester));
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
      expect(find.byType(CharacterStudioPage), findsOneWidget);
      final pane = tester.widget<ResourceWorkspacePane>(
        find.byType(ResourceWorkspacePane),
      );
      final characters = pane.navigation.characters;
      await fixture.capture(tester, 'character-studio-guide');
      await tester.tap(find.text('Nouveau personnage'));
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'Marcheur');
      await tester.tap(find.text('Créer'));
      await pumpIo(tester);
      expect(characters.selectedCharacter?.name, 'Marcheur');
      await fixture.capture(tester, 'character-studio-desktop');
      await tester.tap(find.text('Ajuster la grille'));
      await tester.pump();
      await tester.tap(find.byType(DropdownButton<int>).first);
      await tester.pump();
      await tester.tap(find.text('3 cases').last);
      await tester.pump();
      await tester.tap(find.text('Appliquer'));
      await tester.pump();
      expect(characters.selectedDraft!.frameWidth, 3);
      await tester.tap(find.byType(DropdownButton<double>));
      await tester.pump();
      await tester.tap(find.text('Rapide').last);
      await tester.pump();
      expect(characters.playbackSpeed, 2);
      await tester.tap(find.byKey(const ValueKey('character-source-0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('character-slot-south-0')));
      await tester.pump();
      expect(characters.dirty, isTrue);
      await tester.tap(find.byKey(const ValueKey('character-studio-guide')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('character-studio-marcheur')));
      await tester.pump();
      expect(characters.selectedDraft!.dirty, isTrue);
      await fixture.capture(tester, 'character-studio-edition');
      await tester.tap(find.text('Enregistrer'));
      await pumpIo(tester);
      expect(characters.error, isNull);
      expect(characters.dirty, isFalse);
      final reopened = await tester.runAsync(
        () => LocalMapWorkspaceAdapter().loadProject(fixture.session),
      );
      final clip = reopened!.characters
          .firstWhere((character) => character.name == 'Marcheur')
          .animations
          .firstWhere(
            (animation) =>
                animation.state == CharacterAnimationState.walk &&
                animation.direction == EntityFacing.south,
          );
      expect(clip.frames.first.source, const TilesetSourceRect(x: 0, y: 0));
      expect(clip.sourceAssetId, isNull);
      expect(
        reopened.characters
            .firstWhere((character) => character.name == 'Marcheur')
            .frameWidth,
        3,
      );
      await tester.longPress(
        find.byKey(const ValueKey('character-slot-south-0')),
      );
      await tester.pump();
      expect(characters.selectedDraft!.previewCharacter.animations, isEmpty);
      await tester.tap(find.text('Enregistrer'));
      await pumpIo(tester);
      final afterRemoval = await tester.runAsync(
        () => LocalMapWorkspaceAdapter().loadProject(fixture.session),
      );
      expect(
        afterRemoval!.characters
            .firstWhere((character) => character.name == 'Marcheur')
            .animations,
        isEmpty,
      );
      tester.view.physicalSize = const Size(1024, 640);
      await tester.pumpWidget(fixture.app(tester, textScale: 1.5));
      await pumpIo(tester);
      expect(find.byType(CharacterStudioPage), findsOneWidget);
      expect(find.text('Enregistrer'), findsOneWidget);
      await fixture.capture(tester, 'character-studio-compact');
      var resourcesReady = false;
      fixture.visuals!.settled.then((_) => resourcesReady = true);
      for (var i = 0; i < 100 && !resourcesReady; i++) {
        await pumpIo(tester, frames: 1);
      }
      expect(resourcesReady, isTrue);
      final scroll = find
          .descendant(
            of: find.byKey(const ValueKey('character-studio-narrow-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      tester.state<ScrollableState>(scroll).position.jumpTo(350);
      await tester.pump();
      await fixture.capture(tester, 'character-studio-compact-editor');
      expect(find.text('Découper automatiquement'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await pumpIo(tester);
    },
  );

  testWidgets('a 3 by 4 PNG imports as a draft and saves four directions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(() => M2UiFixture.create(tester)))!;
    addTearDown(fixture.dispose);
    final pickedSheet = await tester.runAsync(() async {
      final atlas = image.Image(width: 96, height: 128, numChannels: 4);
      for (var row = 0; row < 4; row++) {
        for (var column = 0; column < 3; column++) {
          image.fillRect(
            atlas,
            x1: column * 32,
            y1: row * 32,
            x2: column * 32 + 31,
            y2: row * 32 + 31,
            color: image.ColorRgba8(40 + row * 40, 90, 80 + column * 50, 255),
          );
        }
      }
      final bytes = Uint8List.fromList(image.encodePng(atlas));
      final file = File('${fixture.directory.path}/pose-guide.png');
      await file.writeAsBytes(bytes);
      return PickedResourceImage(file.path, 'Pose-guide', bytes, 96, 128);
    });
    await tester.pumpWidget(
      fixture.app(tester, imagePicker: () async => pickedSheet),
    );
    await pumpIo(tester);
    await chooseMapExtraTool(tester, 'Gérer les ressources');
    await pumpIo(tester);
    await tester.tap(find.text('Personnages'));
    await pumpIo(tester);
    await tester.tap(find.text('Importer une planche'));
    await tester.pump();
    await tester.tap(find.text('Importer').last);
    await pumpIo(tester);
    final navigation = tester
        .widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane))
        .navigation;
    final characters = navigation.characters;
    expect(characters.selectedCharacter?.name, 'Pose-guide');
    expect(characters.selectedDraft?.changedClips.length, 4);
    expect(characters.dirty, isTrue);
    var settled = false;
    fixture.visuals!.settled.then((_) => settled = true);
    for (var i = 0; i < 100 && !settled; i++) {
      await pumpIo(tester, frames: 1);
    }
    expect(settled, isTrue);
    final preview = RuntimeAuthoringCharacterRenderer(
      character: characters.selectedDraft!.previewCharacter,
      settings: fixture.controller.project!.settings,
      images: fixture.visuals!.images,
      animationState: CharacterAnimationState.walk,
    );
    expect(
      preview.hasVisual,
      isTrue,
      reason:
          'Loaded: ${fixture.visuals!.images.keys}; '
          'path keys: ${fixture.visuals!.paths.keys}; '
          'same visuals: ${identical(fixture.visuals, navigation.visuals)}; '
          'thumbnails: ${find.byType(StudioCharacterThumbnail).evaluate().length}; '
          'diagnostics: ${fixture.visuals!.diagnostics}',
    );
    await fixture.capture(tester, 'character-studio-import');
    await tester.tap(find.text('Enregistrer'));
    await pumpIo(tester);
    for (var i = 0; i < 100 && characters.saving; i++) {
      await pumpIo(tester, frames: 1);
    }
    expect(characters.saving, isFalse);
    final reopened = await tester.runAsync(
      () => LocalMapWorkspaceAdapter().loadProject(fixture.session),
    );
    final imported = reopened!.characters.firstWhere(
      (character) => character.name == 'Pose-guide',
    );
    expect(imported.frameWidth, 2);
    expect(imported.frameHeight, 2);
    expect(imported.animations, hasLength(4));
    expect(
      imported.animations.every((clip) => clip.frames.length == 3),
      isTrue,
    );
    await tester.tap(find.text('Ajuster la grille'));
    await tester.pump();
    await tester.tap(find.byType(DropdownButton<int>).first);
    await tester.pump();
    await tester.tap(find.text('3 cases').last);
    await tester.pump();
    await tester.tap(find.text('Appliquer'));
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await pumpIo(tester);
    expect(characters.error, contains('sort de la planche'));
    expect(characters.dirty, isTrue);
    final unchanged = await tester.runAsync(
      () => LocalMapWorkspaceAdapter().loadProject(fixture.session),
    );
    expect(
      unchanged!.characters
          .firstWhere((character) => character.name == 'Pose-guide')
          .frameWidth,
      2,
    );
    await tester.pumpWidget(const SizedBox());
    await pumpIo(tester);
  });
}
