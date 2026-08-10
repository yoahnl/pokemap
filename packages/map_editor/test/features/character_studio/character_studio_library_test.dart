import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/character_studio/application/character_studio_media_resolver.dart';
import 'package:map_editor/src/features/character_studio/presentation/library/character_studio_library.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  testWidgets('library searches and filters project characters', (
    tester,
  ) async {
    final project = _project();
    String? selectedId;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 780,
            child: CharacterStudioLibrary(
              project: project,
              selectedCharacterId: null,
              onSelect: (id) => selectedId = id,
              onCreate: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Élia'), findsOneWidget);
    expect(find.text('Nox'), findsOneWidget);
    expect(find.text('Marchande'), findsOneWidget);
    expect(find.text('0 portraits · 2 animations'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('character-sprite-thumbnail-elia')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('character-filter-players')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Élia'), findsOneWidget);
    expect(find.text('Nox'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('character-filter-npc')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Élia'), findsNothing);
    expect(find.text('Nox'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('character-library-search')),
      'march',
    );
    await tester.pumpAndSettle();
    expect(find.text('Marchande'), findsOneWidget);
    expect(find.text('Nox'), findsNothing);

    await tester.tap(find.text('Marchande'));
    expect(selectedId, 'merchant');
    expect(tester.takeException(), isNull);
  });

  testWidgets('create flow exposes tileset names instead of raw ids', (
    tester,
  ) async {
    CharacterCreateDraft? draft;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 780,
            child: CharacterStudioLibrary(
              project: _project(),
              selectedCharacterId: null,
              onSelect: (_) {},
              onCreate: (value) => draft = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('character-create-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nouveau personnage'), findsWidgets);
    expect(find.text('Sprites des héros'), findsWidgets);
    expect(find.text('characters_main'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('character-create-name')),
      'Prof. Orme',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('character-create-confirm')),
    );
    await tester.pumpAndSettle();

    expect(draft?.name, 'Prof. Orme');
    expect(draft?.tilesetId, 'characters_main');
  });

  testWidgets('library resolves portable animation assets for thumbnails', (
    tester,
  ) async {
    final base = _project();
    final project = base.copyWith(
      characters: <ProjectCharacterEntry>[
        base.characters.first.copyWith(
          animations: const <CharacterAnimation>[
            CharacterAnimation(
              state: CharacterAnimationState.idle,
              direction: EntityFacing.south,
              sourceAssetId: 'elia-base-asset',
              frames: <CharacterAnimationFrame>[
                CharacterAnimationFrame(source: TilesetSourceRect(x: 2, y: 3)),
              ],
            ),
          ],
        ),
        ...base.characters.skip(1),
      ],
    );
    final resolver = _RecordingResolver();
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 780,
            child: CharacterStudioLibrary(
              project: project,
              selectedCharacterId: 'elia',
              projectRootPath: '/tmp/character-studio-assets',
              projectRevision: 'revision-7',
              mediaResolver: resolver,
              onSelect: (_) {},
              onCreate: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(resolver.requests, hasLength(1));
    expect(resolver.requests.single.assetId, 'elia-base-asset');
    expect(resolver.requests.single.projectRevision, 'revision-7');
  });
}

final class _RecordingResolver implements CharacterStudioMediaResolverContract {
  final List<CharacterStudioMediaRequest> requests =
      <CharacterStudioMediaRequest>[];
  final Completer<Uint8List> _pending = Completer<Uint8List>();

  @override
  Future<Uint8List> resolve(CharacterStudioMediaRequest request) {
    requests.add(request);
    return _pending.future;
  }
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Character Studio',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'characters_main',
        name: 'Sprites des héros',
        relativePath: 'tilesets/characters.png',
      ),
    ],
    characters: <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'elia',
        name: 'Élia',
        tilesetId: 'characters_main',
        tags: <String>['héroïne'],
        animations: <CharacterAnimation>[
          for (final direction in EntityFacing.values)
            CharacterAnimation(
              state: CharacterAnimationState.idle,
              direction: direction,
              frames: <CharacterAnimationFrame>[
                CharacterAnimationFrame(
                  source: TilesetSourceRect(x: direction.index, y: 0),
                ),
              ],
            ),
        ],
        customAnimations: <CharacterCustomAnimationClip>[
          for (final direction in <EntityFacing>[
            EntityFacing.south,
            EntityFacing.north,
          ])
            CharacterCustomAnimationClip(
              definitionId: 'wave',
              direction: direction,
              sourceAssetId: 'characters_main',
              frames: const <CharacterAnimationFrame>[
                CharacterAnimationFrame(source: TilesetSourceRect(x: 0, y: 1)),
              ],
            ),
        ],
      ),
      ProjectCharacterEntry(
        id: 'nox',
        name: 'Nox',
        tilesetId: 'characters_main',
        tags: <String>['rival'],
      ),
      ProjectCharacterEntry(
        id: 'merchant',
        name: 'Marchande',
        tilesetId: 'characters_main',
        tags: <String>['commerce'],
      ),
    ],
    settings: const ProjectSettings(defaultPlayerCharacterId: 'elia'),
  );
}
