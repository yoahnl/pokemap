import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('states source fidelity and local simulation honestly', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationLivePreview(
          profile: ProjectPresentationProfile(theme: safeProjectSemanticTheme),
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          scene: PersonalizationStudioScene.dialogue,
        ),
      ),
    );

    expect(find.text('Aperçu'), findsOneWidget);
    expect(find.text('Données de démonstration'), findsOneWidget);
    expect(find.text('Interface du jeu'), findsOneWidget);
    expect(find.text('Aperçu uniquement'), findsOneWidget);
    expect(find.text('Aperçu en direct'), findsNothing);
    expect(find.text('Preview réelle'), findsNothing);
  });

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

  testWidgets('renders authored dialogue on the project map backdrop', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PersonalizationLivePreview(
          profile: const ProjectPresentationProfile(
            theme: safeProjectSemanticTheme,
          ),
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          scene: PersonalizationStudioScene.dialogue,
          contentSource: PersonalizationPreviewContentSource.project,
          contexts: _projectContexts,
        ),
      ),
    );

    expect(find.text('Données du projet'), findsOneWidget);
    expect(find.text('Interface du jeu · décor éditeur'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('personalization-project-map-backdrop'),
      ),
      findsOneWidget,
    );
    expect(find.byType(PlayerDialogueSurface), findsOneWidget);
    expect(find.text('Bienvenue à Vermeil.'), findsOneWidget);
    expect(find.text('Léo'), findsOneWidget);
    expect(find.text('Professeure Saule'), findsNothing);
  });

  testWidgets('renders authored encounter data with the shared battle widget', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PersonalizationLivePreview(
          profile: const ProjectPresentationProfile(
            theme: safeProjectSemanticTheme,
          ),
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          scene: PersonalizationStudioScene.battle,
          contentSource: PersonalizationPreviewContentSource.project,
          contexts: _projectContexts,
        ),
      ),
    );

    final surface = tester.widget<PlayerBattleSurface>(
      find.byType(PlayerBattleSurface),
    );
    expect(surface.data.enemy.speciesLabel, 'Roucool');
    expect(surface.data.player.speciesLabel, 'Brindibou');
    expect(find.text('Professeure Saule'), findsNothing);
  });
}

final _projectContexts = <PersonalizationPreviewContextOption>[
  PersonalizationPreviewContextOption(
    id: 'map:vermeil_village',
    kind: PersonalizationPreviewContextKind.map,
    sourceId: 'vermeil_village',
    label: 'Village de Vermeil',
    availability: 'ready',
    diagnosticCodes: const <String>[],
    detail: const <String, Object?>{
      'map': <String, Object?>{
        'id': 'vermeil_village',
        'name': 'Village de Vermeil',
        'size': <String, Object?>{'width': 12, 'height': 8},
        'version': 'v6',
      },
    },
  ),
  PersonalizationPreviewContextOption(
    id: 'dialogue:welcome_leo',
    kind: PersonalizationPreviewContextKind.dialogue,
    sourceId: 'welcome_leo',
    label: 'Bienvenue de Léo',
    availability: 'ready',
    diagnosticCodes: const <String>[],
    detail: const <String, Object?>{
      'dialogue': <String, Object?>{
        'source': <String, Object?>{
          'text':
              'title: Start\n---\n<<portrait leo happy>>\n'
              'Bienvenue à Vermeil.\n===',
        },
      },
    },
  ),
  PersonalizationPreviewContextOption(
    id: 'characterPortrait:leo:happy',
    kind: PersonalizationPreviewContextKind.characterPortrait,
    sourceId: 'leo',
    label: 'Léo · Heureux',
    availability: 'ready',
    diagnosticCodes: const <String>[],
    detail: const <String, Object?>{
      'characterName': 'Léo',
      'portraitStateId': 'happy',
    },
  ),
  PersonalizationPreviewContextOption(
    id: 'encounter:vermeil_grass',
    kind: PersonalizationPreviewContextKind.encounter,
    sourceId: 'vermeil_grass',
    label: 'Herbes de Vermeil',
    availability: 'ready',
    diagnosticCodes: const <String>[],
    detail: const <String, Object?>{
      'entries': <Object?>[
        <String, Object?>{
          'speciesId': 'roucool',
          'minLevel': 7,
          'maxLevel': 7,
          'weight': 1,
        },
      ],
      'playerPokemon': <String, Object?>{
        'speciesId': 'brindibou',
        'level': 8,
        'currentHp': 24,
        'knownMoveIds': <String>['charge'],
      },
    },
  ),
];

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(
    body: Center(child: SizedBox(width: 1000, height: 700, child: child)),
  ),
);
