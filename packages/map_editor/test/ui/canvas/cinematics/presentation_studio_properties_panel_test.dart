import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_property_command.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_layer_tree.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_properties_panel.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_player_ui/presentation_renderer.dart';

void main() {
  setUpAll(() async {
    final bytes = await File(
      '${Directory.current.path}/../../examples/playable_runtime_host/'
      'golden_personalization_v3/assets/presentation/fonts/display.ttf',
    ).readAsBytes();
    for (final family in <String>['Aube Display', 'Avenir Next', 'Roboto']) {
      await (FontLoader(family)
            ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes))))
          .load();
    }
  });

  testWidgets('English properties remain readable at 200 percent text scale', (
    tester,
  ) async {
    final selection = PresentationStudioSelectionController();
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(
      tester,
      asset: _asset(),
      selection: selection,
      commands: commands,
      locale: const Locale('en'),
      textScaler: const TextScaler.linear(2),
      width: 520,
    );

    expect(find.text('Properties'), findsOneWidget);
    expect(find.text('Document'), findsOneWidget);
    expect(find.text('Duration (seconds)'), findsOneWidget);
    expect(find.text('Responsive composition'), findsOneWidget);
    expect(find.text('Safe areas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('document validation stays inline and keeps the selection', (
    tester,
  ) async {
    final selection = PresentationStudioSelectionController();
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(
      tester,
      asset: _asset(),
      selection: selection,
      commands: commands,
    );

    expect(find.text('Document'), findsOneWidget);
    expect(find.text('Composition responsive'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey<String>('presentation-property-title')),
      '   ',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Le titre est obligatoire.'), findsOneWidget);
    expect(commands, isEmpty);
    expect(selection.value, isNull);

    await tester.enterText(
      find.byKey(const ValueKey<String>('presentation-property-title')),
      'Nouvelle ouverture',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(commands.single.actionId, 'presentationCinematic.update');
    expect(commands.single.parameters['title'], 'Nouvelle ouverture');
  });

  testWidgets('visual inspector resets only the active orientation override', (
    tester,
  ) async {
    final asset = _asset();
    final selection = PresentationStudioSelectionController()
      ..selectClip(asset: asset, clipId: 'image');
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(
      tester,
      asset: asset,
      selection: selection,
      commands: commands,
      orientation: PresentationFrameOrientation.portrait,
    );

    expect(find.text('Média responsive'), findsOneWidget);
    expect(find.text('Composition · Portrait 9:16'), findsOneWidget);
    expect(find.text('Transitions et animation'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const ValueKey<String>('presentation-property-reset-composition'),
      ),
    );
    await tester.pump();

    final encoded = commands.single.parameters['clip']! as Map;
    expect(encoded['portraitCompositionOverride'], isNull);
    expect(encoded['landscapeCompositionOverride'], isNotNull);
    expect(selection.value?.clipId, 'image');
  });

  testWidgets('visual media kind emits the canonical typed payload', (
    tester,
  ) async {
    final asset = _asset();
    final selection = PresentationStudioSelectionController()
      ..selectClip(asset: asset, clipId: 'image');
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(tester, asset: asset, selection: selection, commands: commands);
    final dropdown = find.byType(DropdownButton<PresentationVisualMediaKind>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vidéo').last);
    await tester.pumpAndSettle();

    final clip = commands.single.parameters['clip']! as Map;
    expect(clip['contentKind'], 'media');
    expect(clip['mediaKind'], 'video');
  });

  testWidgets('text keeps Unicode input without exposing raw color syntax', (
    tester,
  ) async {
    final asset = _asset();
    final selection = PresentationStudioSelectionController()
      ..selectClip(asset: asset, clipId: 'text');
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(tester, asset: asset, selection: selection, commands: commands);
    const content = 'Bienvenue à Avelune 🐉';
    await tester.enterText(
      find.byKey(const ValueKey<String>('presentation-property-text')),
      content,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final clip = commands.single.parameters['clip']! as Map;
    expect(clip['text'], content);
    expect((clip['style']! as Map)['colorHex'], '#FFFFFF');
    expect(selection.value?.clipId, 'text');
    expect(
      find.byKey(
        const ValueKey<String>('presentation-property-text-color-picker'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('text position and visual color picker emit canonical values', (
    tester,
  ) async {
    final asset = _asset();
    final selection = PresentationStudioSelectionController()
      ..selectClip(asset: asset, clipId: 'text');
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(
      tester,
      asset: asset,
      selection: selection,
      commands: commands,
      locale: const Locale('en'),
    );
    await tester.enterText(
      find.byKey(
        const ValueKey<String>('presentation-property-text-position-x'),
      ),
      '0.25',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final positioned = commands.removeLast().parameters['clip']! as Map;
    expect(
      (positioned['landscapeCompositionOverride']! as Map)['translateX'],
      0.25,
    );
    expect(positioned['portraitCompositionOverride'], isNull);

    await tester.ensureVisible(
      find.byKey(
        const ValueKey<String>('presentation-property-text-color-picker'),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('presentation-property-text-color-picker'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(pokeMapColorPickerDialogKey), findsOneWidget);
    expect(find.text('Hue'), findsOneWidget);
    expect(find.text('Saturation'), findsOneWidget);
    expect(find.text('Brightness'), findsOneWidget);
    expect(find.text('Opacity'), findsOneWidget);
    expect(find.text('Hexadecimal (advanced)'), findsOneWidget);

    await tester.enterText(
      find.byKey(pokeMapColorPickerHexFieldKey),
      '#33669980',
    );
    await tester.tap(find.byKey(pokeMapColorPickerApplyKey));
    await tester.pumpAndSettle();

    final colored = commands.single.parameters['clip']! as Map;
    expect((colored['style']! as Map)['colorHex'], '#33669980');

    await tester.tap(
      find.byKey(
        const ValueKey<String>('presentation-property-text-color-picker'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('pokemap-color-recent-0')),
      findsOneWidget,
    );
  });

  testWidgets('registry dispatches text audio caption and marker inspectors', (
    tester,
  ) async {
    final asset = _asset();
    final selection = PresentationStudioSelectionController();
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(
      tester,
      asset: asset,
      selection: selection,
      commands: commands,
      markerUsageCountById: const <String, int>{'cue': 2},
    );

    Future<void> select(String clipId, String expectedTitle) async {
      selection.selectClip(asset: asset, clipId: clipId);
      await tester.pump();
      expect(find.text(expectedTitle), findsOneWidget);
    }

    await select('text', 'Texte');
    await tester.enterText(
      find.byKey(const ValueKey<String>('presentation-property-text')),
      'Bienvenue à Avelune',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(commands.single.actionId, 'presentationClip.update');
    expect(
      (commands.single.parameters['clip']! as Map)['text'],
      'Bienvenue à Avelune',
    );

    await select('music', 'Audio');
    expect(find.text('Source partagée'), findsOneWidget);
    expect(find.text('Source paysage'), findsNothing);

    await select('caption', 'Sous-titres');
    expect(find.text('Fallback locale projet'), findsOneWidget);

    await select('cue', 'Repère et interaction');
    expect(find.text('2 usages dans Scene'), findsOneWidget);
  });

  testWidgets('audio type and fades emit typed audio properties', (
    tester,
  ) async {
    final asset = _asset();
    final selection = PresentationStudioSelectionController()
      ..selectClip(asset: asset, clipId: 'music');
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(tester, asset: asset, selection: selection, commands: commands);
    await tester.enterText(
      find.byKey(const ValueKey<String>('presentation-property-fade-in')),
      '1.5',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(
      (commands.removeLast().parameters['clip']! as Map)['fadeInUs'],
      1500000,
    );

    final typeDropdown = find.byType(DropdownButton<PresentationAudioKind>);
    await tester.ensureVisible(typeDropdown);
    await tester.tap(typeDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voix').last);
    await tester.pumpAndSettle();

    final clip = commands.single.parameters['clip']! as Map;
    expect(clip['audioKind'], 'voice');
    expect(clip['bus'], 'voice');
  });

  testWidgets('authoritative rebuild refreshes document and text inputs', (
    tester,
  ) async {
    final selection = PresentationStudioSelectionController();
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(
      tester,
      asset: _asset(),
      selection: selection,
      commands: commands,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('presentation-property-title')),
          )
          .controller
          ?.text,
      'Ouverture',
    );

    final restored = _asset(title: 'Ouverture restaurée', text: 'Bon retour');
    await _pump(
      tester,
      asset: restored,
      selection: selection,
      commands: commands,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('presentation-property-title')),
          )
          .controller
          ?.text,
      'Ouverture restaurée',
    );

    selection.selectClip(asset: restored, clipId: 'text');
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('presentation-property-text')),
          )
          .controller
          ?.text,
      'Bon retour',
    );

    await _pump(
      tester,
      asset: _asset(title: 'Ouverture restaurée', text: 'Encore une fois'),
      selection: selection,
      commands: commands,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('presentation-property-text')),
          )
          .controller
          ?.text,
      'Encore une fois',
    );
  });

  testWidgets('caption locale and timing validate before authoring', (
    tester,
  ) async {
    final asset = _asset();
    final selection = PresentationStudioSelectionController()
      ..selectClip(asset: asset, clipId: 'caption');
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(tester, asset: asset, selection: selection, commands: commands);
    await tester.enterText(
      find.byKey(
        const ValueKey<String>('presentation-property-caption-locale'),
      ),
      ' ',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('presentation-property-caption-start')),
      '9',
    );
    await tester.enterText(
      find.byKey(
        const ValueKey<String>('presentation-property-caption-duration'),
      ),
      '2',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('La locale est obligatoire.'), findsOneWidget);
    expect(
      find.text('Le timing doit être positif et rester dans le document.'),
      findsWidgets,
    );
    expect(commands, isEmpty);

    await tester.enterText(
      find.byKey(
        const ValueKey<String>('presentation-property-caption-locale'),
      ),
      'en-US',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('presentation-property-caption-start')),
      '1',
    );
    await tester.enterText(
      find.byKey(
        const ValueKey<String>('presentation-property-caption-duration'),
      ),
      '2',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final clip = commands.single.parameters['clip']! as Map;
    expect(clip['locale'], 'en-US');
    expect(clip['startUs'], 1000000);
    expect(clip['durationUs'], 2000000);
  });

  testWidgets('marker name validation keeps the selected cue', (tester) async {
    final asset = _asset();
    final selection = PresentationStudioSelectionController()
      ..selectClip(asset: asset, clipId: 'cue');
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(tester, asset: asset, selection: selection, commands: commands);
    final field = find.byKey(
      const ValueKey<String>('presentation-property-marker-name'),
    );
    await tester.enterText(field, ' ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Le nom est obligatoire.'), findsOneWidget);
    expect(commands, isEmpty);
    expect(selection.value?.clipId, 'cue');

    await tester.enterText(field, 'Choisir le starter');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(
      (commands.single.parameters['clip']! as Map)['label'],
      'Choisir le starter',
    );
    expect((commands.single.parameters['clip']! as Map)['id'], 'cue');
  });

  testWidgets('transition kind emits a bounded canonical transition', (
    tester,
  ) async {
    final asset = _asset();
    final selection = PresentationStudioSelectionController()
      ..selectClip(asset: asset, clipId: 'image');
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(tester, asset: asset, selection: selection, commands: commands);
    final dropdowns = find.byType(
      DropdownButton<PresentationVisualTransitionKind>,
    );
    await tester.ensureVisible(dropdowns.first);
    await tester.tap(dropdowns.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fondu').last);
    await tester.pumpAndSettle();

    final transition =
        ((commands.single.parameters['clip']! as Map)['transitionIn']! as Map);
    expect(transition['kind'], 'fade');
    expect(transition['durationUs'], inInclusiveRange(1, 10000000));
  });

  testWidgets('mixed selection is explicit and does not emit a mutation', (
    tester,
  ) async {
    final asset = _asset();
    final selection = PresentationStudioSelectionController()
      ..selectClip(asset: asset, clipId: 'image');
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(
      tester,
      asset: asset,
      selection: selection,
      commands: commands,
      selectedClipIds: const <String>{'image', 'text'},
    );

    expect(find.text('Sélection multiple'), findsOneWidget);
    expect(find.text('2 clips sélectionnés'), findsOneWidget);
    expect(find.text('Média responsive'), findsNothing);
    expect(commands, isEmpty);
  });

  testWidgets('golden: the branches card in the real dark panel', (
    tester,
  ) async {
    final selection = PresentationStudioSelectionController();
    addTearDown(selection.dispose);

    await tester.binding.setSurfaceSize(const Size(372, 1180));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pump(
      tester,
      asset: _asset(),
      selection: selection,
      commands: <PresentationStudioPropertyCommand>[],
      width: 372,
      height: 1180,
      markerUsageCountById: const <String, int>{'cue': 1},
      cueViews: <String, PresentationCueAuthoringView>{
        'cue': PresentationCueAuthoringView(
          markerId: 'cue',
          sceneId: 'intro',
          presentationNodeId: 'presentation',
          awaitableNodeId: 'confirm_name',
          awaitableLabel: 'Confirmer le nom',
          awaitableKind: SceneNodeKind.action,
          outputPortIds: const <String>['confirmed', 'declined'],
          routes: <ScenePresentationCueOutcomeRoute>[
            ScenePresentationCueOutcomeRoute(
              outputPortId: 'declined',
              outcome: PresentationInteractionOutcome.repeatFromMarker(
                markerId: 'cue',
              ),
            ),
          ],
        ),
      },
    );
    selection.selectClip(asset: _asset(), clipId: 'cue');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(PresentationStudioPropertiesPanel),
      matchesGoldenFile('goldens/cue_branches/dark_panel.png'),
    );
  });

  testWidgets('an unlinked cue explains itself instead of faking a binding', (
    tester,
  ) async {
    final selection = PresentationStudioSelectionController();
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(
      tester,
      asset: _asset(),
      selection: selection,
      commands: commands,
      width: 520,
    );
    selection.selectClip(asset: _asset(), clipId: 'cue');
    await tester.pump();

    expect(find.text('Branches'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('cue-branches-unlinked')),
      findsOneWidget,
    );
    expect(commands, isEmpty);
  });

  testWidgets('routing an output emits the Scene action, continue clears it', (
    tester,
  ) async {
    final selection = PresentationStudioSelectionController();
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(
      tester,
      asset: _asset(),
      selection: selection,
      commands: commands,
      width: 520,
      cueViews: <String, PresentationCueAuthoringView>{
        'cue': const PresentationCueAuthoringView(
          markerId: 'cue',
          sceneId: 'intro',
          presentationNodeId: 'presentation',
          awaitableNodeId: 'confirm_name',
          awaitableLabel: 'Confirmer le nom',
          awaitableKind: SceneNodeKind.action,
          outputPortIds: <String>['confirmed', 'declined'],
          routes: <ScenePresentationCueOutcomeRoute>[],
        ),
      },
    );
    selection.selectClip(asset: _asset(), clipId: 'cue');
    await tester.pump();

    expect(
      find.textContaining('Confirmer le nom'),
      findsOneWidget,
      reason: 'the linked node and its output count share one line',
    );
    expect(
      find.byKey(const ValueKey<String>('cue-branch-outcome-declined')),
      findsOneWidget,
      reason: 'one row per output port of the bound node',
    );
    expect(
      find.byKey(const ValueKey<String>('cue-branch-destination-declined')),
      findsNothing,
      reason: 'a continuation needs no destination',
    );

    final outcomeDropdown = find.descendant(
      of: find.byKey(const ValueKey<String>('cue-branch-outcome-declined')),
      matching: find.byType(DropdownButton<PresentationInteractionOutcomeKind>),
    );
    await tester.ensureVisible(outcomeDropdown);
    await tester.tap(outcomeDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rejouer').last);
    await tester.pumpAndSettle();

    expect(commands, hasLength(1));
    expect(commands.single.actionId, 'scene.presentation.cue.routes.set');
    expect(commands.single.parameters['sceneId'], 'intro');
    expect(commands.single.parameters['markerId'], 'cue');
    expect(
      commands.single.parameters['routes'],
      [
        {
          'outputPortId': 'declined',
          'outcome': {'kind': 'repeatFromMarker', 'markerId': 'cue'},
        },
      ],
      reason: 'the only marker of the fixture is the default destination',
    );
  });

  testWidgets('an already routed output offers its destination and clears', (
    tester,
  ) async {
    final selection = PresentationStudioSelectionController();
    final commands = <PresentationStudioPropertyCommand>[];
    addTearDown(selection.dispose);

    await _pump(
      tester,
      asset: _asset(),
      selection: selection,
      commands: commands,
      width: 520,
      cueViews: <String, PresentationCueAuthoringView>{
        'cue': PresentationCueAuthoringView(
          markerId: 'cue',
          sceneId: 'intro',
          presentationNodeId: 'presentation',
          awaitableNodeId: 'confirm_name',
          awaitableLabel: 'Confirmer le nom',
          awaitableKind: SceneNodeKind.action,
          outputPortIds: const <String>['confirmed', 'declined'],
          routes: <ScenePresentationCueOutcomeRoute>[
            ScenePresentationCueOutcomeRoute(
              outputPortId: 'declined',
              outcome: PresentationInteractionOutcome.repeatFromMarker(
                markerId: 'cue',
              ),
            ),
          ],
        ),
      },
    );
    selection.selectClip(asset: _asset(), clipId: 'cue');
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('cue-branch-destination-declined')),
      findsOneWidget,
      reason: 'a replay exposes the cue it comes back to',
    );

    final outcomeDropdown = find.descendant(
      of: find.byKey(const ValueKey<String>('cue-branch-outcome-declined')),
      matching: find.byType(DropdownButton<PresentationInteractionOutcomeKind>),
    );
    await tester.ensureVisible(outcomeDropdown);
    await tester.tap(outcomeDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer').last);
    await tester.pumpAndSettle();

    expect(
      commands.single.parameters['routes'],
      isEmpty,
      reason: 'continuing is the default: it is stored as no route at all',
    );
  });

}

Future<void> _pump(
  WidgetTester tester, {
  required PresentationCinematicAsset asset,
  required PresentationStudioSelectionController selection,
  required List<PresentationStudioPropertyCommand> commands,
  PresentationFrameOrientation orientation =
      PresentationFrameOrientation.landscape,
  Map<String, int> markerUsageCountById = const <String, int>{},
  Map<String, PresentationCueAuthoringView> cueViews =
      const <String, PresentationCueAuthoringView>{},
  Set<String> selectedClipIds = const <String>{},
  Locale locale = const Locale('fr'),
  TextScaler textScaler = TextScaler.noScaling,
  double width = 360,
  double height = 760,
}) => tester.pumpWidget(
  MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: PokeMapTheme.dark(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: Scaffold(
      body: SizedBox(
        width: width,
        height: height,
        child: PresentationStudioPropertiesPanel(
          asset: asset,
          selectionController: selection,
          orientation: orientation,
          onCommand: commands.add,
          markerUsageCountById: markerUsageCountById,
          cueViews: cueViews,
          selectedClipIds: selectedClipIds,
        ),
      ),
    ),
  ),
);

PresentationCinematicAsset _asset({
  String title = 'Ouverture',
  String text = 'Bienvenue',
}) => PresentationCinematicAsset(
  id: 'opening',
  title: title,
  description: 'Introduction',
  durationUs: 10_000_000,
  layers: <PresentationLayer>[
    PresentationLayer(id: 'image-layer', label: 'Image', zIndex: 0),
    PresentationLayer(id: 'text-layer', label: 'Titre', zIndex: 1),
  ],
  tracks: <PresentationTrack>[
    PresentationTrack(
      id: 'visuals',
      label: 'Visuels',
      kind: PresentationTrackKind.visual,
      clips: <PresentationClip>[
        PresentationVisualClip(
          id: 'image',
          startUs: 0,
          durationUs: 10_000_000,
          layerId: 'image-layer',
          resourceId: 'image-shared',
          landscapeCompositionOverride: PresentationVisualComposition(
            translateX: -.1,
          ),
          portraitCompositionOverride: PresentationVisualComposition(
            translateY: .1,
          ),
        ),
        PresentationTextClip(
          id: 'text',
          startUs: 0,
          durationUs: 5_000_000,
          layerId: 'text-layer',
          text: text,
        ),
      ],
    ),
    PresentationTrack(
      id: 'audio',
      label: 'Audio',
      kind: PresentationTrackKind.audio,
      clips: <PresentationClip>[
        PresentationAudioClip(
          id: 'music',
          startUs: 0,
          durationUs: 10_000_000,
          resourceId: 'music-shared',
        ),
      ],
    ),
    PresentationTrack(
      id: 'captions',
      label: 'Sous-titres',
      kind: PresentationTrackKind.caption,
      clips: <PresentationClip>[
        PresentationCaptionClip(
          id: 'caption',
          startUs: 0,
          durationUs: 3_000_000,
          captionId: 'caption-fr',
          locale: 'fr-FR',
        ),
      ],
    ),
    PresentationTrack(
      id: 'markers',
      label: 'Repères',
      kind: PresentationTrackKind.marker,
      clips: <PresentationClip>[
        PresentationMarkerClip(
          id: 'cue',
          startUs: 5_000_000,
          label: 'Demander le nom',
          markerKind: PresentationMarkerKind.interactionCue,
          required: true,
        ),
      ],
    ),
  ],
);
