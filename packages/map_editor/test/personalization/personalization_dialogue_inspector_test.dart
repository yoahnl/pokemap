import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/presentation/inspectors/personalization_dialogue_inspector.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('commits one dialogue change after a slider gesture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final committed = <ProjectDialoguePresentationProfile?>[];

    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: PersonalizationDialogueInspector(
            profile: const ProjectPresentationProfile(),
            characterOptions: _characters,
            selectedCharacterId: 'leo:happy',
            showPortrait: true,
            showName: true,
            showChoices: false,
            onCharacterSelected: (_) {},
            onShowPortraitChanged: (_) {},
            onShowNameChanged: (_) {},
            onShowChoicesChanged: (_) {},
            onDialogueChanged: committed.add,
            onImportDialogueFont: () {},
            onUseSystemDialogueFont: () {},
          ),
        ),
      ),
    );

    final slider = find.descendant(
      of: find.byKey(const ValueKey<String>('dialogue-geometry-width')),
      matching: find.byType(CupertinoSlider),
    );
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    final control = tester.widget<CupertinoSlider>(slider);
    control.onChangeStart?.call(82);
    for (final value in <double>[80, 78, 76, 74, 72, 70]) {
      control.onChanged?.call(value);
    }
    expect(committed, isEmpty);
    control.onChangeEnd?.call(70);

    expect(committed, hasLength(1));
  });

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
                    contexts: _dialogueContexts,
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
        matching: find.text('Leo'),
      ),
      findsOneWidget,
    );

    await _toggle(tester, 'dialogue-preview-name');
    expect(
      find.descendant(
        of: find.byType(PlayerDialogueSurface),
        matching: find.text('Leo'),
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

  testWidgets('shows dialogue color inheritance and resets one override', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ProjectDialoguePresentationProfile? changed;
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: PersonalizationDialogueInspector(
            profile: const ProjectPresentationProfile(
              surfacePalettes: ProjectPresentationSurfacePalettesProfile(
                dialogue: ProjectSurfacePaletteProfile(surface: '#FFFFFF'),
              ),
              dialogue: ProjectDialoguePresentationProfile(
                maxWidthFactor: .72,
                surfaceColor: '#102030',
              ),
            ),
            characterOptions: _characters,
            selectedCharacterId: 'leo:happy',
            showPortrait: true,
            showName: true,
            showChoices: false,
            onCharacterSelected: (_) {},
            onShowPortraitChanged: (_) {},
            onShowNameChanged: (_) {},
            onShowChoicesChanged: (_) {},
            onDialogueChanged: (dialogue) => changed = dialogue,
            onImportDialogueFont: () {},
            onUseSystemDialogueFont: () {},
          ),
        ),
      ),
    );

    expect(find.text('Surcharge de scène'), findsOneWidget);
    expect(find.text('Hérité de Style global'), findsNWidgets(8));
    final reset = find.byKey(
      const ValueKey<String>('dialogue-color-inherit-surface'),
    );
    await tester.ensureVisible(reset);
    await tester.pumpAndSettle();
    await tester.tap(reset);

    expect(changed?.surfaceColor, isNull);
    expect(changed?.maxWidthFactor, .72);
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

final _dialogueContexts = <PersonalizationPreviewContextOption>[
  PersonalizationPreviewContextOption(
    id: 'dialogue:leo',
    kind: PersonalizationPreviewContextKind.dialogue,
    sourceId: 'leo',
    label: 'Dialogue de Léo',
    availability: 'ready',
    diagnosticCodes: const <String>[],
    detail: const <String, Object?>{
      'dialogue': <String, Object?>{
        'source': <String, Object?>{
          'text':
              'title: Start\n---\n'
              '<<portrait leo happy>>\n'
              'Bienvenue à Vermeil.\n'
              '-> Oui, allons-y !\n'
              '  Parfait.\n'
              '-> Pas encore.\n'
              '  Prends ton temps.\n'
              '===',
        },
      },
    },
  ),
];

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: child),
);
