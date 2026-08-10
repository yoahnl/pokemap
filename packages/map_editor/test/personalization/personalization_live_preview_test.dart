import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('exposes only the simple product simulation controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationLivePreview(
          profile: ProjectPresentationProfile(theme: safeProjectSemanticTheme),
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          scene: PersonalizationStudioScene.title,
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-viewport-landscape'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-viewport-portrait'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-viewport-square'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'personalization-preview-viewport-phoneLandscape',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-text-scale-100'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-text-scale-125'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-text-scale-150'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-text-scale-200'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('simulation changes stay local to the live preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const profile = ProjectPresentationProfile(
      menuLabels: ProjectMenuLabelsProfile(pokedex: 'Carnet'),
      theme: safeProjectSemanticTheme,
    );
    await tester.pumpWidget(
      _app(
        const PersonalizationLivePreview(
          profile: profile,
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          scene: PersonalizationStudioScene.title,
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-viewport-portrait'),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-text-scale-200'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>(
          'personalization-preview-viewport-frame-portrait',
        ),
      ),
      findsOneWidget,
    );
    final surfaceContext = tester.element(find.byType(PlayerTitleSurface));
    expect(MediaQuery.textScalerOf(surfaceContext).scale(10), 20);
    expect(profile.menuLabels?.pokedex, 'Carnet');
  });

  testWidgets('reduced motion is offered only for title and intro', (
    tester,
  ) async {
    var scene = PersonalizationStudioScene.title;
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return PersonalizationLivePreview(
              profile: const ProjectPresentationProfile(
                theme: safeProjectSemanticTheme,
              ),
              projectName: 'Pokémon Aurore',
              projectRootPath: '',
              scene: scene,
            );
          },
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-reduced-motion'),
      ),
      findsOneWidget,
    );

    setHostState(() => scene = PersonalizationStudioScene.pause);
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-reduced-motion'),
      ),
      findsNothing,
    );

    setHostState(() => scene = PersonalizationStudioScene.intro);
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('personalization-preview-reduced-motion'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('real player controls emit contextual inspector targets', (
    tester,
  ) async {
    PersonalizationInspectorTarget? target;
    var scene = PersonalizationStudioScene.pause;
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return PersonalizationLivePreview(
              profile: const ProjectPresentationProfile(
                theme: safeProjectSemanticTheme,
              ),
              projectName: 'Pokémon Aurore',
              projectRootPath: '',
              scene: scene,
              onTargeted: (value) => target = value,
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('pause.party')));
    await tester.pump();
    expect(target, isA<PauseLabelsTarget>());

    setHostState(() => scene = PersonalizationStudioScene.dialogue);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('dialogue-tap-zone')));
    await tester.pump();
    expect(target, isA<DialogueAppearanceTarget>());

    setHostState(() => scene = PersonalizationStudioScene.battle);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ATTAQUER'));
    await tester.pump();
    expect(target, isA<BattleCommandsTarget>());
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(
    body: Center(child: SizedBox(width: 1000, height: 700, child: child)),
  ),
);
