import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
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

    expect(find.text('Aperçu en direct'), findsOneWidget);
    expect(find.text('Projet réel'), findsOneWidget);
    expect(find.text('Widgets du jeu'), findsOneWidget);
    expect(find.text('Réglages d’essai'), findsOneWidget);
    expect(find.text('Aperçu'), findsNothing);
    expect(find.text('Données de démonstration'), findsNothing);
    expect(find.text('Interface du jeu'), findsNothing);
    expect(
      find.text(
        'Sélectionnez un dialogue du projet pour afficher cette scène.',
      ),
      findsOneWidget,
    );
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
    final segmentedControls = tester.widgetList<PokeMapSegmentedTabs>(
      find.byType(PokeMapSegmentedTabs),
    );
    expect(
      segmentedControls
          .expand((control) => control.tabs)
          .map((tab) => tab.semanticLabel),
      containsAll(<String>[
        'Paysage, aperçu uniquement',
        '200 %, aperçu uniquement',
      ]),
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
              contexts: _projectContexts,
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

  testWidgets('global preview hit testing selects the related inspector', (
    tester,
  ) async {
    PersonalizationInspectorTarget? target;
    await tester.pumpWidget(
      _app(
        PersonalizationLivePreview(
          profile: const ProjectPresentationProfile(
            theme: safeProjectSemanticTheme,
          ),
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          scene: PersonalizationStudioScene.globalStyle,
          onTargeted: (value) => target = value,
        ),
      ),
    );

    final surface = find.byKey(
      const ValueKey<String>('personalization-preview-target-global-style'),
    );
    final bounds = tester.getRect(surface);
    await tester.tapAt(
      Offset(bounds.center.dx, bounds.top + bounds.height * .2),
    );
    await tester.pump();
    expect(target, isA<GlobalTypographyTarget>());

    await tester.tapAt(
      Offset(bounds.center.dx, bounds.top + bounds.height * .8),
    );
    await tester.pump();
    expect(target, isA<GlobalFormsTarget>());
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

    expect(find.text('Projet réel'), findsOneWidget);
    expect(find.text('Widgets du jeu sur la carte du projet'), findsOneWidget);
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

  testWidgets('renders neutral dialogue content in demonstration mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationLivePreview(
          profile: ProjectPresentationProfile(theme: safeProjectSemanticTheme),
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          scene: PersonalizationStudioScene.dialogue,
          contentSource: PersonalizationPreviewContentSource.demonstration,
        ),
      ),
    );

    expect(find.text('Démonstration'), findsOneWidget);
    expect(find.byType(PlayerDialogueSurface), findsOneWidget);
    expect(
      find.text('Voici comment votre dialogue apparaîtra dans le jeu.'),
      findsOneWidget,
    );
    expect(find.text('Personnage'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('personalization-dialogue-demo-portrait'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-dialogue-unavailable'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-project-map-backdrop'),
      ),
      findsNothing,
    );
  });

  testWidgets('demonstration dialogue exercises choices without a portrait', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationLivePreview(
          profile: ProjectPresentationProfile(theme: safeProjectSemanticTheme),
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          scene: PersonalizationStudioScene.dialogue,
          contentSource: PersonalizationPreviewContentSource.demonstration,
          showDialoguePortrait: false,
          showDialogueChoices: true,
        ),
      ),
    );

    expect(find.byType(PlayerDialogueSurface), findsOneWidget);
    expect(find.text('Premier choix'), findsOneWidget);
    expect(find.text('Deuxième choix'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('personalization-dialogue-demo-portrait'),
      ),
      findsNothing,
    );
  });

  testWidgets('switches between real dialogue scenarios from the project', (
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

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'personalization-preview-context-dialogueScenario',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choix de bienvenue').last);
    await tester.pumpAndSettle();

    expect(find.text('Partir explorer'), findsOneWidget);
    expect(find.text('Rester au village'), findsOneWidget);
    expect(find.text('Professeure Saule'), findsNothing);
  });

  testWidgets('keeps a real text-only scenario free of demo portraits', (
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
          dialogueCharacter: const PersonalizationCharacterPreviewOption(
            id: 'leo:happy',
            characterId: 'leo',
            displayName: 'Léo',
            portraitPath: null,
            expressionId: 'happy',
            expressionLabel: 'Heureux',
            workspaceRevision: 'revision',
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'personalization-preview-context-dialogueScenario',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Narration sans portrait').last);
    await tester.pumpAndSettle();

    expect(find.text('Le vent se lève.'), findsOneWidget);
    expect(find.text('Léo'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('personalization-dialogue-portrait')),
      findsNothing,
    );
  });

  testWidgets('recovers when a selected project scenario disappears', (
    tester,
  ) async {
    var contexts = _projectContexts;
    late StateSetter update;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return PersonalizationLivePreview(
              profile: const ProjectPresentationProfile(
                theme: safeProjectSemanticTheme,
              ),
              projectName: 'Pokémon Aurore',
              projectRootPath: '',
              scene: PersonalizationStudioScene.dialogue,
              contentSource: PersonalizationPreviewContentSource.project,
              contexts: contexts,
            );
          },
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'personalization-preview-context-dialogueScenario',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choix de bienvenue').last);
    await tester.pumpAndSettle();
    expect(find.text('Partir explorer'), findsOneWidget);

    update(() {
      contexts = _projectContexts
          .where((context) => context.id != 'dialogueScenario:welcome_leo:0:2')
          .toList(growable: false);
    });
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue à Vermeil.'), findsOneWidget);
    expect(find.text('Partir explorer'), findsNothing);
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
    expect(find.byType(PlayerBattleScene), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('personalization-project-map-backdrop'),
      ),
      findsOneWidget,
    );
    expect(surface.data.enemy.speciesLabel, 'Roucool');
    expect(surface.data.player.speciesLabel, 'Brindibou');
    expect(find.text('Professeure Saule'), findsNothing);
  });

  for (final entry
      in <(PersonalizationBattlePreviewState, PlayerBattlePanelKind)>[
        (
          PersonalizationBattlePreviewState.commands,
          PlayerBattlePanelKind.commands,
        ),
        (PersonalizationBattlePreviewState.moves, PlayerBattlePanelKind.moves),
        (
          PersonalizationBattlePreviewState.target,
          PlayerBattlePanelKind.target,
        ),
        (
          PersonalizationBattlePreviewState.message,
          PlayerBattlePanelKind.message,
        ),
      ]) {
    testWidgets(
      'renders neutral ${entry.$1.name} battle content in demonstration mode',
      (tester) async {
        await tester.pumpWidget(
          _app(
            PersonalizationLivePreview(
              profile: const ProjectPresentationProfile(
                theme: safeProjectSemanticTheme,
              ),
              projectName: 'Pokémon Aurore',
              projectRootPath: '',
              scene: PersonalizationStudioScene.battle,
              contentSource: PersonalizationPreviewContentSource.demonstration,
              battleState: entry.$1,
            ),
          ),
        );

        final surface = tester.widget<PlayerBattleSurface>(
          find.byType(PlayerBattleSurface),
        );
        expect(find.text('Démonstration'), findsOneWidget);
        expect(find.byType(PlayerBattleScene), findsOneWidget);
        expect(surface.data.panelKind, entry.$2);
        expect(surface.data.enemy.speciesLabel, 'Créature adverse');
        expect(surface.data.player.speciesLabel, 'Partenaire');
        expect(
          find.byKey(
            const ValueKey<String>('personalization-battle-unavailable'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey<String>('personalization-project-map-backdrop'),
          ),
          findsNothing,
        );
      },
    );
  }

  for (final entry
      in <(PersonalizationBattlePreviewState, PersonalizationInspectorTarget)>{
        (
          PersonalizationBattlePreviewState.commands,
          const BattleCommandsTarget(),
        ),
        (PersonalizationBattlePreviewState.moves, const BattleMovesTarget()),
        (PersonalizationBattlePreviewState.target, const BattleTargetsTarget()),
        (
          PersonalizationBattlePreviewState.message,
          const BattleMessageTarget(),
        ),
      }) {
    testWidgets('targets ${entry.$1.name} inspector from its live panel', (
      tester,
    ) async {
      PersonalizationInspectorTarget? target;
      await tester.pumpWidget(
        _app(
          PersonalizationLivePreview(
            profile: const ProjectPresentationProfile(
              theme: safeProjectSemanticTheme,
            ),
            projectName: 'Pokémon Aurore',
            projectRootPath: '',
            scene: PersonalizationStudioScene.battle,
            battleState: entry.$1,
            contexts: _projectContexts,
            onTargeted: (value) => target = value,
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('battle-command-panel')),
      );
      await tester.pump();

      expect(target.runtimeType, entry.$2.runtimeType);
    });
  }

  testWidgets('targets HUD controls directly from the live HUD', (
    tester,
  ) async {
    PersonalizationInspectorTarget? target;
    await tester.pumpWidget(
      _app(
        PersonalizationLivePreview(
          profile: const ProjectPresentationProfile(
            theme: safeProjectSemanticTheme,
          ),
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          scene: PersonalizationStudioScene.battle,
          contexts: _projectContexts,
          onTargeted: (value) => target = value,
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('battle-hud-target-enemy')),
    );
    await tester.pump();

    expect(target, isA<BattleHudTarget>());
  });

  testWidgets(
    'selects both project creatures without persisting preview state',
    (tester) async {
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

      await tester.tap(
        find.byKey(const ValueKey<String>('battle-preview-enemy')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mystherbe').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('battle-preview-player')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pikachu').last);
      await tester.pumpAndSettle();

      final surface = tester.widget<PlayerBattleSurface>(
        find.byType(PlayerBattleSurface),
      );
      expect(surface.data.enemy.speciesLabel, 'Mystherbe');
      expect(surface.data.player.speciesLabel, 'Pikachu');
    },
  );

  testWidgets('projects the drag ghost before committing its layout', (
    tester,
  ) async {
    final previews = <ProjectPresentationLayoutsProfile>[];
    final commits = <ProjectPresentationLayoutsProfile>[];
    await tester.pumpWidget(
      _app(
        PersonalizationLivePreview(
          profile: const ProjectPresentationProfile(
            theme: safeProjectSemanticTheme,
          ),
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          scene: PersonalizationStudioScene.pause,
          onLayoutPreviewChanged: previews.add,
          onLayoutCommitted: commits.add,
        ),
      ),
    );

    final dragZone = find.byKey(
      const ValueKey<String>('personalization-layout-drag-zone'),
    );
    expect(dragZone, findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(dragZone));
    await tester.pump();
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(Offset(tester.getSize(dragZone).width * .4, 0));
    await tester.pump();

    expect(previews, isNotEmpty);
    expect(
      previews.last.pauseMenu.expanded.slot,
      ProjectPresentationLayoutSlot.right,
    );
    expect(commits, isEmpty);

    await gesture.up();
    await tester.pump();

    expect(commits, hasLength(1));
    expect(
      commits.single.pauseMenu.expanded.slot,
      ProjectPresentationLayoutSlot.right,
    );
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
    id: 'dialogueScenario:welcome_leo:0:0',
    kind: PersonalizationPreviewContextKind.dialogueScenario,
    sourceId: 'welcome_leo',
    label: 'Réplique de Léo',
    availability: 'ready',
    diagnosticCodes: const <String>[],
    detail: const <String, Object?>{
      'scenarioKind': 'characterLine',
      'stepIndex': 0,
      'characterId': 'leo',
      'characterName': 'Léo',
      'portraitStateId': 'happy',
      'text': 'Bienvenue à Vermeil.',
    },
  ),
  PersonalizationPreviewContextOption(
    id: 'dialogueScenario:welcome_leo:0:1',
    kind: PersonalizationPreviewContextKind.dialogueScenario,
    sourceId: 'welcome_leo',
    label: 'Narration sans portrait',
    availability: 'ready',
    diagnosticCodes: const <String>[],
    detail: const <String, Object?>{
      'scenarioKind': 'textLine',
      'stepIndex': 1,
      'text': 'Le vent se lève.',
    },
  ),
  PersonalizationPreviewContextOption(
    id: 'dialogueScenario:welcome_leo:0:2',
    kind: PersonalizationPreviewContextKind.dialogueScenario,
    sourceId: 'welcome_leo',
    label: 'Choix de bienvenue',
    availability: 'ready',
    diagnosticCodes: const <String>[],
    detail: const <String, Object?>{
      'scenarioKind': 'choice',
      'stepIndex': 2,
      'choices': <Object?>[
        <String, Object?>{'label': 'Partir explorer'},
        <String, Object?>{'label': 'Rester au village'},
      ],
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
      'characterId': 'leo',
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
          'displayName': 'Roucool',
          'minLevel': 7,
          'maxLevel': 7,
          'weight': 1,
        },
        <String, Object?>{
          'speciesId': 'mystherbe',
          'displayName': 'Mystherbe',
          'minLevel': 6,
          'maxLevel': 8,
          'weight': 1,
        },
      ],
      'playerPokemon': <String, Object?>{
        'speciesId': 'brindibou',
        'displayName': 'Brindibou',
        'level': 8,
        'currentHp': 24,
        'knownMoveIds': <String>['charge'],
      },
      'playerPokemonOptions': <Object?>[
        <String, Object?>{
          'speciesId': 'brindibou',
          'displayName': 'Brindibou',
          'level': 8,
          'currentHp': 24,
          'knownMoveIds': <String>['charge'],
        },
        <String, Object?>{
          'speciesId': 'pikachu',
          'displayName': 'Pikachu',
          'level': 9,
          'currentHp': 30,
          'knownMoveIds': <String>['eclair'],
        },
      ],
    },
  ),
];

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(
    body: Center(child: SizedBox(width: 1000, height: 700, child: child)),
  ),
);
