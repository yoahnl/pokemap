import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/character_studio/application/character_animation_matrix_model.dart';
import 'package:map_editor/src/features/character_studio/application/character_studio_media_resolver.dart';
import 'package:map_editor/src/features/character_studio/presentation/animations/animation_matrix.dart';
import 'package:map_editor/src/features/character_studio/presentation/animations/character_studio_animations_tab.dart';
import 'package:map_editor/src/features/character_studio/presentation/preview/character_studio_sprite_thumbnail.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  testWidgets('grid exposes required optional invalid and single slots', (
    tester,
  ) async {
    final model = _model();
    await tester.pumpWidget(_harness(model));

    expect(find.text('Base'), findsOneWidget);
    expect(find.text('Requis manquant'), findsWidgets);
    expect(find.text('Optionnel manquant'), findsWidgets);
    expect(find.text('Invalide'), findsOneWidget);
    expect(find.text('2 frames'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('animation-slot-custom-jump-single')),
      findsOneWidget,
    );
    expect(find.text('Unique'), findsOneWidget);
  });

  testWidgets(
    'keyboard selection and filters preserve a visible focus target',
    (tester) async {
      final model = _model();
      CharacterAnimationSlotKey? selected = model.rows.first.slots.first.key;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return SizedBox(
                  width: 980,
                  height: 760,
                  child: AnimationMatrix(
                    model: model,
                    selectedKey: selected,
                    onSelected: (key) {
                      selected = key;
                      rebuild(() {});
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(ValueKey<String>('animation-slot-${selected!.stableId}')),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(selected, model.rows.first.slots[1].key);

      await tester.tap(
        find.byKey(const ValueKey<String>('animation-matrix-filter-missing')),
      );
      await tester.pump();

      expect(
        find.byKey(ValueKey<String>('animation-slot-${selected!.stableId}')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('animation-matrix-focus-ring')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'character tab renders the live matrix and global manager entry',
    (tester) async {
      final project = _project();
      var manageRequestCount = 0;
      final resolver = _ImmediateMediaResolver();

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 980,
              height: 760,
              child: CharacterStudioAnimationsTab(
                project: project,
                character: project.characters.single,
                projectRootPath: '/project',
                projectRevision: '1',
                mediaResolver: resolver,
                isSaving: false,
                onManageDefinitions: () => manageRequestCount += 1,
                onImportSource: (_) async => true,
                onSaveClip: (_, _, _) async => true,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('character-studio-animations-tab')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('animation-matrix')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      final thumbnailFinder = find.byKey(
        const ValueKey<String>('animation-slot-thumbnail-system-idle-south'),
      );
      expect(thumbnailFinder, findsOneWidget);
      expect(
        tester
            .widget<CharacterStudioSpriteThumbnail>(thumbnailFinder)
            .usesPixelCoordinates,
        isTrue,
      );
      expect(resolver.requests.map((request) => request.assetId), <String>[
        'elia-idle-south',
      ]);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('character-studio-create-custom-animation'),
        ),
      );

      expect(manageRequestCount, 1);

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'character-studio-manage-animation-definitions',
          ),
        ),
      );

      expect(manageRequestCount, 2);
    },
  );
}

final class _ImmediateMediaResolver
    implements CharacterStudioMediaResolverContract {
  final List<CharacterStudioMediaRequest> requests =
      <CharacterStudioMediaRequest>[];

  @override
  Future<Uint8List> resolve(CharacterStudioMediaRequest request) async {
    requests.add(request);
    return base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLzNwAAAABJRU5ErkJggg==',
    );
  }
}

Widget _harness(CharacterAnimationMatrixModel model) {
  return MaterialApp(
    theme: PokeMapTheme.dark(),
    home: Scaffold(
      body: SizedBox(
        width: 980,
        height: 760,
        child: AnimationMatrix(
          model: model,
          selectedKey: model.rows.first.slots.first.key,
          onSelected: (_) {},
        ),
      ),
    ),
  );
}

CharacterAnimationMatrixModel _model() {
  final project = _project();
  return CharacterAnimationMatrixModel.build(
    project: project,
    character: project.characters.single,
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Matrix',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
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
            sourceAssetId: 'elia-idle-south',
            frames: <CharacterAnimationFrame>[
              CharacterAnimationFrame(source: TilesetSourceRect(x: 0, y: 0)),
              CharacterAnimationFrame(source: TilesetSourceRect(x: 1, y: 0)),
            ],
          ),
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.east,
          ),
        ],
      ),
    ],
  );
}
