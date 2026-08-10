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
                selectedCharacterId: 'leo',
                showPortrait: true,
                showName: true,
                showChoices: false,
                onCharacterSelected: (_) {},
                onShowPortraitChanged: (_) {},
                onShowNameChanged: (_) {},
                onShowChoicesChanged: (_) {},
                onWindowsChanged: (windows) => setHostState(
                  () => profile = profile.copyWith(windows: windows),
                ),
                onLayoutsChanged: (layouts) => setHostState(
                  () => profile = profile.copyWith(layouts: layouts),
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
    expect(
      find.byKey(const ValueKey<String>('window-target-pause')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('window-field-corner-radius')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('window-field-border-width')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('window-field-fill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('typography-import-dialogue')),
      findsOneWidget,
    );

    final centered = find.byKey(
      const ValueKey<String>('dialogue-layout-center'),
    );
    await tester.ensureVisible(centered);
    await tester.pumpAndSettle();
    expect(centered.hitTestable(), findsOneWidget);
    await tester.tap(centered);
    await tester.pumpAndSettle();

    expect(
      profile.layouts?.dialogue.compact.slot,
      ProjectPresentationLayoutSlot.center,
    );
    expect(
      profile.layouts?.dialogue.regular.slot,
      ProjectPresentationLayoutSlot.center,
    );
    expect(
      profile.layouts?.dialogue.expanded.slot,
      ProjectPresentationLayoutSlot.center,
    );
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
                      selectedCharacterId: 'leo',
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
                      onWindowsChanged: (_) {},
                      onLayoutsChanged: (_) {},
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
    characterId: 'leo',
    displayName: 'Léo',
    portraitPath: null,
    expressionId: 'happy',
  ),
];

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: child),
);
