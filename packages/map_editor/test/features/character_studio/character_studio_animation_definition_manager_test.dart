import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/character_studio/application/character_animation_definition_use_cases.dart';
import 'package:map_editor/src/features/character_studio/presentation/catalog/animation_definition_manager.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('system definitions are immutable and custom order is global', (
    tester,
  ) async {
    List<String>? reordered;
    await tester.pumpWidget(
      _harness(
        AnimationDefinitionManager(
          project: _project(),
          isSaving: false,
          onCreate: (_, _) async {},
          onUpdate: (_, _, _) async {},
          onReorder: (ids) async => reordered = ids,
          onPreviewDelete: (_) async => _deletePlan(),
          onDelete: (_, _, _) async {},
        ),
      ),
    );

    expect(find.text('Base'), findsOneWidget);
    expect(find.text('Marche'), findsOneWidget);
    expect(find.text('Course'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('animation-definition-delete-base')),
      findsNothing,
    );
    expect(find.text('1/2 personnages'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Saluer'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.getTopLeft(find.text('Saut')).dy,
      lessThan(tester.getTopLeft(find.text('Saluer')).dy),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('animation-definition-move-down-jump')),
    );
    await tester.pump();

    expect(reordered, <String>['wave', 'jump']);
  });

  testWidgets('creation rejects reserved ids and preserves the chosen mode', (
    tester,
  ) async {
    (String, CharacterCustomAnimationMode)? created;
    await tester.pumpWidget(
      _harness(
        AnimationDefinitionManager(
          project: _project(),
          isSaving: false,
          onCreate: (label, mode) async => created = (label, mode),
          onUpdate: (_, _, _) async {},
          onReorder: (_) async {},
          onPreviewDelete: (_) async => _deletePlan(),
          onDelete: (_, _, _) async {},
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('animation-definition-create')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('animation-definition-name-field')),
      'Base',
    );
    await tester.pump();

    expect(find.text('Identifiant réservé au système.'), findsOneWidget);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(
              const ValueKey<String>('animation-definition-create-confirm'),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('animation-definition-name-field')),
      'Danse de victoire',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('animation-definition-mode-single')),
    );
    await tester.pump();
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(
              const ValueKey<String>('animation-definition-create-confirm'),
            ),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('animation-definition-create-confirm')),
    );
    await tester.pumpAndSettle();

    expect(created, ('Danse de victoire', CharacterCustomAnimationMode.single));
  });

  testWidgets('referenced definition cannot silently migrate its mode', (
    tester,
  ) async {
    (String, String?, CharacterCustomAnimationMode?)? updated;
    await tester.pumpWidget(
      _harness(
        AnimationDefinitionManager(
          project: _project(),
          isSaving: false,
          onCreate: (_, _) async {},
          onUpdate: (id, label, mode) async => updated = (id, label, mode),
          onReorder: (_) async {},
          onPreviewDelete: (_) async => _deletePlan(),
          onDelete: (_, _, _) async {},
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('animation-definition-edit-wave')),
      320,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('animation-definition-edit-wave')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('animation-definition-mode-single')),
    );
    await tester.pump();

    expect(
      find.text('Retirez d’abord les clips existants dans la matrice.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(
              const ValueKey<String>('animation-definition-update-confirm'),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(updated, isNull);
  });

  testWidgets('delete plan requires an explicit clip resolution', (
    tester,
  ) async {
    (String, AnimationDefinitionDeleteResolution, String?)? deleted;
    await tester.pumpWidget(
      _harness(
        AnimationDefinitionManager(
          project: _project(),
          isSaving: false,
          onCreate: (_, _) async {},
          onUpdate: (_, _, _) async {},
          onReorder: (_) async {},
          onPreviewDelete: (_) async => _deletePlan(),
          onDelete: (id, resolution, replacementId) async {
            deleted = (id, resolution, replacementId);
          },
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('animation-definition-delete-wave')),
      320,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('animation-definition-delete-wave')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Personnage · Élia'), findsOneWidget);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(
              const ValueKey<String>('animation-definition-delete-confirm'),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('animation-definition-delete-resolution-clear'),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('animation-definition-delete-confirm')),
    );
    await tester.pumpAndSettle();

    expect(deleted, ('wave', AnimationDefinitionDeleteResolution.clear, null));
  });
}

Widget _harness(Widget child) {
  return MaterialApp(
    theme: PokeMapTheme.dark(),
    home: Scaffold(body: SizedBox(width: 820, height: 820, child: child)),
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Animations',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
        CharacterCustomAnimationDefinition(
          id: 'wave',
          displayName: 'Saluer',
          mode: CharacterCustomAnimationMode.directional,
          sortOrder: 2,
        ),
        CharacterCustomAnimationDefinition(
          id: 'jump',
          displayName: 'Saut',
          mode: CharacterCustomAnimationMode.single,
        ),
      ],
    ),
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'elia',
        name: 'Élia',
        tilesetId: 'elia',
        animations: <CharacterAnimation>[
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            frames: <CharacterAnimationFrame>[
              CharacterAnimationFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
          ),
        ],
        customAnimations: <CharacterCustomAnimationClip>[
          CharacterCustomAnimationClip(
            definitionId: 'wave',
            direction: EntityFacing.south,
            sourceAssetId: 'elia-wave',
          ),
        ],
      ),
      ProjectCharacterEntry(id: 'nox', name: 'Nox', tilesetId: 'nox'),
    ],
  );
}

AnimationDefinitionDeletePlan _deletePlan() {
  return const AnimationDefinitionDeletePlan(
    animationDefinitionId: 'wave',
    requiresResolution: true,
    dependencies: <AnimationDefinitionDeleteDependency>[
      AnimationDefinitionDeleteDependency(
        sourceKind: 'characterAnimation',
        sourceId: 'elia',
        path: r'$.characters[0].customAnimations[0]',
      ),
    ],
    replacementCandidates: <AnimationDefinitionReplacementCandidate>[
      AnimationDefinitionReplacementCandidate(
        id: 'other-wave',
        displayName: 'Autre salut',
        mode: CharacterCustomAnimationMode.directional,
      ),
    ],
  );
}
