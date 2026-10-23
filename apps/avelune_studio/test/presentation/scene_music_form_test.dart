import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets(
    'scene music uses known music pickers and clears incompatible operation fields',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final applied = <SceneNodePayload>[];
      final project = ProjectManifest(
        name: 'Musique',
        maps: const [],
        tilesets: const [],
        cinematicMediaAssets: [
          CinematicMediaAsset(
            id: 'theme',
            label: 'Thème musical',
            kind: CinematicMediaAssetKind.music,
            relativePath: 'audio/theme.ogg',
          ),
          CinematicMediaAsset(
            id: 'sound',
            label: 'Son à exclure',
            kind: CinematicMediaAssetKind.sound,
            relativePath: 'audio/sound.ogg',
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 450,
              child: SceneActionForm(
                project: project,
                current: SceneActionPayload.interactive(
                  SceneInteractiveCommand.sceneMusic(
                    operation: SceneMusicOperation.play,
                    mediaAssetId: 'theme',
                    volume: .8,
                  ),
                ),
                onApply: applied.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      Finder select(String label) =>
          find.byWidgetPredicate((w) => w is StudioSelect && w.label == label);
      Future<void> pick(String label, String text) async {
        await tester.tap(
          find.descendant(
            of: select(label),
            matching: find.byType(DropdownButtonFormField<String>),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      Finder apply() => find.byWidgetPredicate(
        (w) => w is StudioButton && w.label == 'Appliquer l’action',
      );
      expect(
        tester.widget<StudioSelect>(select('Action musicale')).options.keys,
        ['play', 'restore', 'fadeOut', 'stop', 'memorize', 'restoreMemorized'],
      );
      expect(tester.widget<StudioSelect>(select('Musique en boucle')).options, {
        'theme': 'Thème musical',
      });
      await tester.tap(apply());
      expect(
        (applied.last as SceneActionPayload).interactiveCommand!.toJson(),
        {
          'kind': 'sceneMusic',
          'operation': 'play',
          'mediaAssetId': 'theme',
          'volume': .8,
        },
      );
      await pick('Canal', 'Ambiance sonore');
      await pick('Durée de vie', 'Jusqu’au prochain transfert');
      await tester.tap(apply());
      expect(
        (applied.last as SceneActionPayload).interactiveCommand!.toJson(),
        {
          'kind': 'sceneMusic',
          'operation': 'play',
          'channel': 'ambience',
          'scope': 'map',
          'mediaAssetId': 'theme',
          'volume': .8,
        },
      );
      await pick('Canal', 'Musique');
      await pick('Durée de vie', 'Pendant la scène');
      await pick('Action musicale', 'Restaurer l’état initial');
      expect(select('Musique en boucle'), findsNothing);
      await tester.tap(apply());
      expect(
        (applied.last as SceneActionPayload).interactiveCommand!.toJson(),
        {'kind': 'sceneMusic', 'operation': 'restore'},
      );
      await pick('Action musicale', 'Fondre puis arrêter');
      expect(select('Musique en boucle'), findsNothing);
      final field = find.descendant(
        of: find.byKey(const ValueKey('action-sceneMusic-durationMs')),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, '60001');
      await tester.pump();
      expect(tester.widget<StudioButton>(apply()).onPressed, isNull);
      await tester.enterText(field, '0');
      await tester.pump();
      await tester.tap(apply());
      expect(
        (applied.last as SceneActionPayload).interactiveCommand!.toJson(),
        {'kind': 'sceneMusic', 'operation': 'fadeOut', 'durationMs': 0},
      );
      await pick('Action musicale', 'Mémoriser');
      await pick('Canal', 'Les deux canaux');
      await tester.tap(apply());
      expect(
        (applied.last as SceneActionPayload).interactiveCommand!.toJson(),
        {
          'kind': 'sceneMusic',
          'operation': 'memorize',
          'channel': 'both',
          'scope': 'scene',
        },
      );
      await pick('Action musicale', 'Arrêter');
      expect(tester.widget<StudioSelect>(select('Canal')).value, 'music');
      expect(
        tester
            .widget<StudioSelect>(select('Canal'))
            .options
            .containsKey('both'),
        isFalse,
      );
    },
  );
}
