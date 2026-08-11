import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/presentation/inspectors/personalization_dialogue_inspector.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('offers focused dialogue placement appearance and typography', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var profile = const ProjectPresentationProfile();
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return SingleChildScrollView(
              child: PersonalizationDialogueInspector(
                profile: profile,
                characterOptions: _characters,
                selectedCharacterId: 'leo:happy',
                showPortrait: true,
                showName: true,
                showChoices: false,
                onCharacterSelected: (_) {},
                onShowPortraitChanged: (_) {},
                onShowNameChanged: (_) {},
                onShowChoicesChanged: (_) {},
                onDialogueChanged: (dialogue) => setHostState(
                  () => profile = profile.copyWith(dialogue: dialogue),
                ),
                onImportDialogueFont: () {},
                onUseSystemDialogueFont: () {},
              ),
            );
          },
        ),
      ),
    );

    for (final placement in <String>['bottom', 'top', 'center']) {
      expect(
        find.byKey(ValueKey<String>('dialogue-layout-$placement')),
        findsOneWidget,
      );
    }
    for (final field in <String>[
      'shape',
      'width',
      'margin',
      'padding',
      'radius',
      'border',
      'opacity',
    ]) {
      expect(
        find.byKey(ValueKey<String>('dialogue-geometry-$field')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey<String>('typography-import-dialogue')),
      findsOneWidget,
    );
    for (final key in <String>[
      'dialogue-portrait-editor',
      'dialogue-portrait-side-start',
      'dialogue-portrait-side-end',
      'dialogue-portrait-shape',
      'dialogue-portrait-size',
      'dialogue-portrait-frame-width',
      'dialogue-nameplate-editor',
      'dialogue-nameplate-style',
      'dialogue-nameplate-border-width',
      'dialogue-choice-editor',
      'dialogue-choice-shape',
      'dialogue-choice-spacing',
      'dialogue-choice-disabled-opacity',
      'dialogue-progress-editor',
      'dialogue-progress-kind',
      'dialogue-motion-editor',
      'dialogue-motion-transition',
      'dialogue-motion-duration',
    ]) {
      expect(find.byKey(ValueKey<String>(key)), findsOneWidget);
    }

    final centered = find.byKey(
      const ValueKey<String>('dialogue-layout-center'),
    );
    await tester.ensureVisible(centered);
    await tester.pumpAndSettle();
    expect(centered.hitTestable(), findsOneWidget);
    await tester.tap(centered);
    await tester.pumpAndSettle();

    expect(profile.dialogue?.placement, ProjectDialoguePlacement.center);

    final portraitEnd = find.byKey(
      const ValueKey<String>('dialogue-portrait-side-end'),
    );
    await tester.ensureVisible(portraitEnd);
    await tester.pumpAndSettle();
    expect(portraitEnd.hitTestable(), findsOneWidget);
    await tester.tap(portraitEnd);
    await tester.pumpAndSettle();

    expect(profile.dialogue?.portraitSide, ProjectDialoguePortraitSide.end);
  });

  testWidgets('preview toggles drive the shared dialogue surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var showPortrait = true;
    var showName = true;
    var showChoices = false;
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return Row(
              children: <Widget>[
                SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: PersonalizationDialogueInspector(
                      profile: const ProjectPresentationProfile(),
                      characterOptions: _characters,
                      selectedCharacterId: 'leo:happy',
                      showPortrait: showPortrait,
                      showName: showName,
                      showChoices: showChoices,
                      onCharacterSelected: (_) {},
                      onShowPortraitChanged: (value) =>
                          setHostState(() => showPortrait = value),
                      onShowNameChanged: (value) =>
                          setHostState(() => showName = value),
                      onShowChoicesChanged: (value) =>
                          setHostState(() => showChoices = value),
                      onDialogueChanged: (_) {},
                      onImportDialogueFont: () {},
                      onUseSystemDialogueFont: () {},
                    ),
                  ),
                ),
                Expanded(
                  child: PersonalizationLivePreview(
                    profile: const ProjectPresentationProfile(),
                    projectName: 'Pokémon Aurore',
                    projectRootPath: '',
                    scene: PersonalizationStudioScene.dialogue,
                    dialogueCharacter: _characters.single,
                    showDialoguePortrait: showPortrait,
                    showDialogueName: showName,
                    showDialogueChoices: showChoices,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.byType(PlayerDialogueSurface), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('personalization-dialogue-portrait')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(PlayerDialogueSurface),
        matching: find.text('Léo'),
      ),
      findsOneWidget,
    );

    await _toggle(tester, 'dialogue-preview-name');
    expect(
      find.descendant(
        of: find.byType(PlayerDialogueSurface),
        matching: find.text('Léo'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('personalization-dialogue-portrait')),
      findsOneWidget,
    );

    await _toggle(tester, 'dialogue-preview-portrait');
    expect(
      find.byKey(const ValueKey<String>('personalization-dialogue-portrait')),
      findsNothing,
    );

    await _toggle(tester, 'dialogue-preview-choices');
    expect(find.text('Oui, allons-y !'), findsOneWidget);
    expect(find.text('Pas encore.'), findsOneWidget);
  });
}

Future<void> _toggle(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey<String>(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

const _characters = <PersonalizationCharacterPreviewOption>[
  PersonalizationCharacterPreviewOption(
    id: 'leo:happy',
    characterId: 'leo',
    displayName: 'Léo',
    portraitPath: null,
    expressionId: 'happy',
    expressionLabel: 'Joyeux',
    workspaceRevision: 'revision',
  ),
];

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: child),
);
