import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/rendering/contracts/scoped_resource_preview_visuals.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/application/project_resource_preview.dart';
import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'package:avelune_studio/features/resources/domain/project_character_workshop_port.dart';
import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/project_character_workshop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

part 'project_character_workshop_fixture.dart';

void main() {
  testWidgets(
    'edits one clip from the library and keeps the duration on reopen',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 820);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final port = _CharacterEditorPort();
      final previews = ProjectResourcePreviews((_) async => port.project);
      final visuals = _CharacterVisuals();
      var published = 0;
      var wentBack = false;
      Future<void> open() => tester.pumpWidget(
        _workshop(
          previews,
          visuals,
          onBack: () => wentBack = true,
          editor: (
            port: port,
            pickImage: () async => null,
            pending: null,
            retain: (_) {},
            publish: (receipt) {
              published++;
              expect(receipt.revision, 'rev-2');
              previews.invalidate(['character:garden-guide']);
            },
          ),
        ),
      );
      await open();
      await tester.pumpAndSettle();
      expect(find.text('Séquence'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byKey(const ValueKey('character-pose-0')), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('character-pose-duration')),
          matching: find.byType(EditableText),
        ),
        '177',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('177 ms'), findsOneWidget);
      expect(
        port.project.characters.single.animations[1].frames.first.durationMs,
        100,
      );
      await tester.tap(find.text('Portraits'));
      await tester.pumpAndSettle();
      expect(find.text('Séquence'), findsOneWidget);
      await tester.tap(find.text('Retour à la bibliothèque'));
      await tester.pumpAndSettle();
      expect(find.text('Abandonner les modifications'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(wentBack, isFalse);
      expect(find.textContaining('177 ms'), findsOneWidget);

      final save = find.widgetWithText(StudioButton, 'Enregistrer l’animation');
      expect(save.hitTestable(), findsOneWidget);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
      expect(published, 1);
      await tester.tap(find.text('Retour à la bibliothèque'));
      expect(wentBack, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await open();
      await tester.pumpAndSettle();
      expect(find.textContaining('177 ms'), findsOneWidget);
      expect(find.textContaining('100 ms'), findsOneWidget);
    },
  );

  testWidgets('offers an import for an empty direction in a narrow window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(580, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final port = _CharacterEditorPort();
    var picks = 0;
    await tester.pumpWidget(
      _workshop(
        ProjectResourcePreviews((_) async => port.project),
        _CharacterVisuals(),
        editor: (
          port: port,
          pickImage: () async {
            picks++;
            return null;
          },
          pending: null,
          retain: (_) {},
          publish: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(StudioSelect, 'Animation'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('character-direction-north')));
    await tester.pumpAndSettle();
    expect(find.text('Aucune pose pour cette animation'), findsOneWidget);
    await tester.tap(find.text('Importer une planche PNG'));
    await tester.pumpAndSettle();
    expect(picks, 1);
    expect(port.revision, 'rev-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('lists expressions and reads only the selected portrait', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final port = _CharacterEditorPort()..project = _projectWithPortraits;
    await tester.pumpWidget(
      _workshop(
        ProjectResourcePreviews((_) async => port.project),
        _CharacterVisuals(),
        editor: (
          port: port,
          pickImage: () async => null,
          pending: null,
          retain: (_) {},
          publish: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(port.portraitReads, isEmpty);
    await tester.tap(find.text('Portraits'));
    await tester.pumpAndSettle();
    expect(port.portraitReads, ['neutral']);
    expect(find.text('Image associée'), findsNWidgets(2));
    expect(find.text('Sans image'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('character-expression-sad')));
    await tester.pumpAndSettle();
    expect(find.text('Importer un portrait PNG'), findsOneWidget);
    expect(port.portraitReads, ['neutral']);
    await tester.tap(find.byKey(const ValueKey('character-expression-happy')));
    await tester.pumpAndSettle();
    expect(port.portraitReads, ['neutral', 'happy']);
    expect(find.byTooltip('Actions du portrait'), findsOneWidget);
    expect(find.text('Copier la commande de dialogue'), findsNothing);
    await tester.tap(find.byTooltip('Actions du portrait'));
    await tester.pumpAndSettle();
    expect(find.text('Copier la commande de dialogue'), findsOneWidget);
    await tester.tap(find.text('Détacher le portrait'));
    await tester.pumpAndSettle();
    expect(find.text('Détacher « Souriant »'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(port.portraitReads, ['neutral', 'happy']);
  });

  testWidgets('previews the configured poses and pauses off the library tab', (
    tester,
  ) async {
    var reads = 0;
    final previews = ProjectResourcePreviews((entry) async {
      expect(entry.identity, 'character:garden-guide');
      reads++;
      return _project;
    });
    final visuals = _CharacterVisuals();
    Future<void> show({required bool active}) =>
        tester.pumpWidget(_workshop(previews, visuals, active: active));

    await show(active: true);
    await tester.pumpAndSettle();
    expect(visuals.last.animationState, CharacterAnimationState.idle);
    expect(visuals.last.facing, EntityFacing.south);
    expect(visuals.last.elapsedMs, 0);

    await _select(tester, 'Animation', 'Marche');
    expect(visuals.last.animationState, CharacterAnimationState.walk);
    await tester.tap(find.widgetWithText(StudioSelect, 'Direction'));
    await tester.pumpAndSettle();
    expect(find.text('Nord'), findsNothing);
    await tester.tap(find.text('Est').last);
    await tester.pumpAndSettle();
    expect(visuals.last.facing, EntityFacing.east);

    await tester.tap(find.text('Lecture'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(visuals.last.elapsedMs, greaterThan(0));
    await tester.tap(find.text('Pause'));
    await tester.pump();
    final paused = visuals.last.elapsedMs;
    await tester.pump(const Duration(milliseconds: 350));
    expect(visuals.last.elapsedMs, paused);

    await tester.tap(find.text('Lecture'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(visuals.last.elapsedMs, greaterThan(paused));
    await show(active: false);
    final hidden = visuals.last.elapsedMs;
    await tester.pump(const Duration(seconds: 1));
    await show(active: true);
    await tester.pumpAndSettle();
    expect(visuals.last.elapsedMs, hidden);
    expect(find.text('Lecture'), findsOneWidget);
    expect(reads, 1);
  });

  testWidgets('plays a non-looping clip once and can replay it', (
    tester,
  ) async {
    final visuals = _CharacterVisuals();
    await tester.pumpWidget(
      _workshop(ProjectResourcePreviews((_) async => _project), visuals),
    );
    await tester.pumpAndSettle();
    await _select(tester, 'Animation', 'Coupe');
    await tester.tap(find.text('Lecture'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(visuals.last.elapsedMs, 199);
    expect(find.text('Lecture'), findsOneWidget);
    await tester.tap(find.text('Lecture'));
    await tester.pump();
    expect(visuals.last.elapsedMs, 0);
  });

  testWidgets('renames via the library action and keeps the selected preview', (
    tester,
  ) async {
    final visuals = _CharacterVisuals();
    var name = _character.name;
    var reads = 0;
    var renamed = 0;
    var wentBack = false;
    final previews = ProjectResourcePreviews((_) async {
      reads++;
      return _project;
    });
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _workshop(
          previews,
          visuals,
          name: name,
          onRename: () async => setState(() {
            renamed++;
            name = 'Guide des dunes';
          }),
          onBack: () => wentBack = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_character.name), findsOneWidget);
    await _select(tester, 'Animation', 'Marche');
    await tester.tap(find.byTooltip('Actions du personnage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renommer'));
    await tester.pumpAndSettle();
    expect(renamed, 1);
    expect(find.text('Guide des dunes'), findsOneWidget);
    expect(find.text(_character.name), findsNothing);
    expect(visuals.last.animationState, CharacterAnimationState.walk);
    expect(reads, 1);
    await tester.tap(find.text('Retour à la bibliothèque'));
    expect(wentBack, isTrue);
  });

  testWidgets('retries a failed read and handles a character with no clip', (
    tester,
  ) async {
    final visuals = _CharacterVisuals();
    var reads = 0;
    await tester.pumpWidget(
      _workshop(
        ProjectResourcePreviews((_) async {
          if (++reads == 1) throw StateError('preview failed');
          return _project.copyWith(
            characters: [_character.copyWith(animations: [])],
          );
        }),
        visuals,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Impossible de lire le personnage'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune animation renseignée.'), findsOneWidget);
    expect(find.text('Lecture'), findsNothing);
    expect(visuals.last.elapsedMs, 0);
    expect(reads, 2);
  });
}
