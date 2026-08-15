import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_layer_tree.dart';

void main() {
  testWidgets('English layer bank stays reachable at 200 percent', (
    tester,
  ) async {
    final selection = PresentationStudioSelectionController();
    addTearDown(selection.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: PokeMapTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 800,
            child: PresentationStudioLayerTree(
              asset: _asset(),
              playheadUs: 0,
              selectionController: selection,
              onCommand: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Layer bank'), findsOneWidget);
    expect(find.text('Visuals'), findsOneWidget);
    expect(find.text('Captions'), findsOneWidget);
    expect(find.text('Cues'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(
              const ValueKey<String>('presentation-layer-create-folder'),
            ),
          )
          .label,
      contains('Create visual folder'),
    );
    expect(tester.takeException(), isNull);
  });

  test('one selection identity synchronizes canvas, tree and timeline', () {
    final asset = _asset();
    final frame = const PresentationCinematicEvaluator().evaluate(
      asset,
      timeUs: 0,
    );
    final selection = PresentationStudioSelectionController();
    addTearDown(selection.dispose);

    selection.selectCanvas(
      asset: asset,
      frame: frame,
      normalizedPosition: const Offset(0.5, 0.5),
    );
    expect(selection.value?.layerId, 'front');
    expect(selection.value?.clipId, 'clip-front');
    expect(selection.origin, PresentationStudioSelectionOrigin.canvas);

    selection.selectCanvas(
      asset: asset,
      frame: frame,
      normalizedPosition: const Offset(0.5, 0.5),
    );
    expect(selection.value?.layerId, 'back');
    expect(selection.value?.clipId, 'clip-back');

    selection.selectLayer(asset: asset, layerId: 'locked', timeUs: 0);
    expect(selection.value?.layerId, 'locked');
    expect(selection.origin, PresentationStudioSelectionOrigin.layers);

    selection.selectClip(
      asset: asset,
      clipId: 'clip-front',
      origin: PresentationStudioSelectionOrigin.timeline,
    );
    expect(selection.value?.layerId, 'front');
    expect(selection.value?.clipId, 'clip-front');
    expect(selection.origin, PresentationStudioSelectionOrigin.timeline);

    selection.selectClip(
      asset: asset,
      clipId: 'music-clip',
      origin: PresentationStudioSelectionOrigin.properties,
    );
    expect(selection.value?.layerId, isNull);
    expect(selection.value?.trackId, 'music');
    expect(selection.value?.clipId, 'music-clip');
    expect(selection.origin, PresentationStudioSelectionOrigin.properties);

    selection.selectLayer(
      asset: asset,
      layerId: 'back',
      timeUs: 0,
      origin: PresentationStudioSelectionOrigin.properties,
    );
    expect(selection.value?.layerId, 'back');
    expect(selection.value?.clipId, 'clip-back');
    expect(selection.origin, PresentationStudioSelectionOrigin.properties);
  });

  test('canvas cycle resets when pointer, time or stack changes', () {
    final asset = _asset();
    final evaluator = const PresentationCinematicEvaluator();
    final selection = PresentationStudioSelectionController();
    addTearDown(selection.dispose);

    selection.selectCanvas(
      asset: asset,
      frame: evaluator.evaluate(asset, timeUs: 0),
      normalizedPosition: const Offset(0.5, 0.5),
    );
    selection.selectCanvas(
      asset: asset,
      frame: evaluator.evaluate(asset, timeUs: 0),
      normalizedPosition: const Offset(0.5, 0.5),
    );
    expect(selection.value?.layerId, 'back');

    selection.selectCanvas(
      asset: asset,
      frame: evaluator.evaluate(asset, timeUs: 1),
      normalizedPosition: const Offset(0.5, 0.5),
    );
    expect(selection.value?.layerId, 'front');

    selection.selectCanvas(
      asset: asset,
      frame: evaluator.evaluate(asset, timeUs: 1),
      normalizedPosition: const Offset(0.2, 0.2),
    );
    expect(selection.value?.layerId, 'front');
  });

  test('authored text shares the canvas selection identity', () {
    final asset = PresentationCinematicAsset(
      id: 'titles',
      title: 'Titles',
      durationUs: 10,
      layers: <PresentationLayer>[
        PresentationLayer(id: 'title-layer', label: 'Titre', zIndex: 1),
      ],
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'visuals',
          label: 'Visuels',
          kind: PresentationTrackKind.visual,
          clips: <PresentationClip>[
            PresentationTextClip(
              id: 'title',
              startUs: 0,
              durationUs: 10,
              layerId: 'title-layer',
              text: 'Bienvenue',
            ),
          ],
        ),
      ],
    );
    final selection = PresentationStudioSelectionController();
    addTearDown(selection.dispose);

    selection.selectCanvas(
      asset: asset,
      frame: const PresentationCinematicEvaluator().evaluate(asset, timeUs: 0),
      normalizedPosition: const Offset(.5, .5),
    );

    expect(selection.value?.layerId, 'title-layer');
    expect(selection.value?.trackId, 'visuals');
    expect(selection.value?.clipId, 'title');
  });

  testWidgets('layer tree exposes system groups, folders and commands', (
    tester,
  ) async {
    final commands = <PresentationStudioLayerCommand>[];
    final selection = PresentationStudioSelectionController();
    addTearDown(selection.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 720,
            child: PresentationStudioLayerTree(
              asset: _asset(),
              playheadUs: 0,
              selectionController: selection,
              onCommand: commands.add,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Visuels'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Sous-titres'), findsOneWidget);
    expect(find.text('Repères'), findsOneWidget);
    expect(find.text('Personnages'), findsOneWidget);
    expect(find.text('Avant-plan'), findsOneWidget);

    await tester.tap(find.text('Verrouillé'));
    await tester.pump();
    expect(selection.value?.layerId, 'locked');

    await tester.tap(find.bySemanticsLabel('Masquer Avant-plan'));
    await tester.tap(find.bySemanticsLabel('Verrouiller Avant-plan'));

    expect(commands.map((command) => command.actionId), <String>[
      'presentationLayer.setVisibility',
      'presentationLayer.setLocked',
    ]);
    expect(commands.first.parameters, containsPair('visible', false));
    expect(commands.last.parameters, containsPair('locked', true));
  });

  testWidgets('collapsing a visual folder changes no authored state', (
    tester,
  ) async {
    final asset = _asset();
    final before = encodePresentationCinematicAsset(asset);
    final selection = PresentationStudioSelectionController();
    addTearDown(selection.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 720,
            child: PresentationStudioLayerTree(
              asset: asset,
              playheadUs: 0,
              selectionController: selection,
              onCommand: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Replier Personnages'));
    await tester.pump();

    expect(find.text('Avant-plan'), findsNothing);
    expect(find.text('Verrouillé'), findsNothing);
    expect(encodePresentationCinematicAsset(asset), before);
  });

  testWidgets('folder create, rename and delete emit semantic commands', (
    tester,
  ) async {
    final commands = <PresentationStudioLayerCommand>[];
    final selection = PresentationStudioSelectionController();
    addTearDown(selection.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 720,
            child: PresentationStudioLayerTree(
              asset: _asset(),
              playheadUs: 0,
              selectionController: selection,
              onCommand: commands.add,
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('presentation-layer-create-folder')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Décors nocturnes');
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(commands.single.actionId, 'presentationVisualFolder.create');
    expect(commands.single.parameters, <String, Object?>{
      'cinematicId': 'opening',
      'folderId': 'd-cors-nocturnes',
      'label': 'Décors nocturnes',
    });

    await tester.tap(find.bySemanticsLabel('Actions pour Personnages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renommer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Héros');
    await tester.tap(find.text('Renommer'));
    await tester.pumpAndSettle();

    expect(commands.last.actionId, 'presentationVisualFolder.update');
    expect(commands.last.parameters, <String, Object?>{
      'cinematicId': 'opening',
      'folderId': 'characters',
      'label': 'Héros',
    });

    await tester.tap(find.bySemanticsLabel('Actions pour Personnages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer le dossier'));
    await tester.pumpAndSettle();

    expect(commands.last.actionId, 'presentationVisualFolder.delete');
    expect(commands.last.parameters, <String, Object?>{
      'cinematicId': 'opening',
      'folderId': 'characters',
    });
  });
}

PresentationCinematicAsset _asset() => PresentationCinematicAsset(
  id: 'opening',
  title: 'Opening',
  durationUs: 10,
  layers: <PresentationLayer>[
    PresentationLayer(id: 'front', label: 'Avant-plan', zIndex: 3),
    PresentationLayer(
      id: 'locked',
      label: 'Verrouillé',
      zIndex: 2,
      locked: true,
    ),
    PresentationLayer(id: 'hidden', label: 'Masqué', zIndex: 1, visible: false),
    PresentationLayer(id: 'back', label: 'Arrière-plan', zIndex: 0),
  ],
  visualFolders: <PresentationVisualFolder>[
    PresentationVisualFolder(
      id: 'characters',
      label: 'Personnages',
      layerIds: const <String>['front', 'locked', 'hidden'],
    ),
  ],
  tracks: <PresentationTrack>[
    PresentationTrack(
      id: 'visuals',
      label: 'Visuels',
      kind: PresentationTrackKind.visual,
      clips: <PresentationClip>[
        for (final layerId in <String>['front', 'locked', 'hidden', 'back'])
          PresentationVisualClip(
            id: 'clip-$layerId',
            startUs: 0,
            durationUs: 10,
            layerId: layerId,
            resourceId: 'media-$layerId',
          ),
      ],
    ),
    PresentationTrack(
      id: 'music',
      label: 'Musique',
      kind: PresentationTrackKind.audio,
      clips: <PresentationClip>[
        PresentationAudioClip(
          id: 'music-clip',
          startUs: 0,
          durationUs: 10,
          resourceId: 'opening-music',
        ),
      ],
    ),
    PresentationTrack(
      id: 'captions',
      label: 'Sous-titres FR',
      kind: PresentationTrackKind.caption,
    ),
    PresentationTrack(
      id: 'markers',
      label: 'Interactions',
      kind: PresentationTrackKind.marker,
    ),
  ],
);
