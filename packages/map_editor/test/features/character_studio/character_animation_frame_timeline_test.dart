import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/character_studio_authoring_gateway.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/features/character_studio/application/character_animation_clip_use_cases.dart';
import 'package:map_editor/src/features/character_studio/application/character_animation_matrix_model.dart';
import 'package:map_editor/src/features/character_studio/application/character_animation_source_slicing.dart';
import 'package:map_editor/src/features/character_studio/presentation/animations/character_animation_frame_timeline.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  test('timeline operations change only the requested ordered frame list', () {
    const dimensions = CharacterAnimationSourceDimensions(64, 32);
    const frames = <CharacterAnimationFrame>[
      CharacterAnimationFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
        durationMs: 100,
      ),
      CharacterAnimationFrame(
        source: TilesetSourceRect(x: 32, y: 0, width: 32, height: 32),
        durationMs: 200,
      ),
    ];

    final duplicate = CharacterAnimationTimelineEditing.duplicate(
      frames,
      index: 0,
      dimensions: dimensions,
    );
    final reordered = CharacterAnimationTimelineEditing.reorder(
      duplicate,
      fromIndex: 2,
      toIndex: 0,
      dimensions: dimensions,
    );
    final deleted = CharacterAnimationTimelineEditing.delete(
      reordered,
      index: 1,
      dimensions: dimensions,
    );
    final updated = CharacterAnimationTimelineEditing.updateDuration(
      deleted,
      index: 0,
      durationMs: 350,
      dimensions: dimensions,
    );

    expect(updated, hasLength(2));
    expect(updated.first.source.x, 32);
    expect(updated.first.durationMs, 350);
    expect(updated.last.source.x, 0);
    expect(frames.first.durationMs, 100);
  });

  test('timeline refuses an invalid duration before publishing changes', () {
    expect(
      () => CharacterAnimationTimelineEditing.updateDuration(
        const <CharacterAnimationFrame>[
          CharacterAnimationFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
          ),
        ],
        index: 0,
        durationMs: 0,
        dimensions: const CharacterAnimationSourceDimensions(32, 32),
      ),
      throwsA(isA<CharacterAnimationSlicingException>()),
    );
  });

  test(
    'save targets exactly one selected custom slot through the canonical action',
    () async {
      final gateway = _RecordingGateway();
      final useCase = SaveCharacterAnimationClipUseCase(gateway);
      final project = _project();
      const selected = CharacterAnimationSlotKey.custom(
        definitionId: 'jump',
        direction: EntityFacing.east,
      );

      await useCase.execute(
        _Workspace(),
        project,
        characterId: 'elia',
        slotKey: selected,
        sourceAssetId: 'sprite-elia-jump',
        frames: const <CharacterAnimationFrame>[
          CharacterAnimationFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
          ),
        ],
        loop: false,
      );

      expect(gateway.actionId, 'characterStudio.animationClip.upsert');
      expect(gateway.parameters, <String, Object?>{
        'characterId': 'elia',
        'kind': 'custom',
        'definitionId': 'jump',
        'direction': 'east',
        'sourceAssetId': 'sprite-elia-jump',
        'frames': <Object?>[
          const CharacterAnimationFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
          ).toJson(),
        ],
        'loop': false,
      });
    },
  );

  testWidgets(
    'timeline exposes duplicate reorder delete and duration controls',
    (tester) async {
      var frames = const <CharacterAnimationFrame>[
        CharacterAnimationFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
        ),
        CharacterAnimationFrame(
          source: TilesetSourceRect(x: 32, y: 0, width: 32, height: 32),
        ),
      ];
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return SizedBox(
                  width: 700,
                  height: 360,
                  child: CharacterAnimationFrameTimeline(
                    frames: frames,
                    dimensions: const CharacterAnimationSourceDimensions(
                      64,
                      32,
                    ),
                    enabled: true,
                    onChanged: (value) {
                      frames = value;
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
        find.byKey(const ValueKey<String>('animation-frame-duplicate-0')),
      );
      await tester.pump();
      expect(frames, hasLength(3));

      await tester.tap(
        find.byKey(const ValueKey<String>('animation-frame-move-right-0')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('animation-frame-delete-1')),
      );
      await tester.pump();
      expect(frames, hasLength(2));

      await tester.enterText(
        find.byKey(const ValueKey<String>('animation-frame-duration-0')),
        '0',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        find.text('La durée doit être supérieure à 0 ms.'),
        findsOneWidget,
      );
      expect(frames.first.durationMs, 150);
    },
  );
}

final class _RecordingGateway implements CharacterStudioAuthoringGateway {
  String? actionId;
  Map<String, Object?>? parameters;

  @override
  Future<ProjectManifest> apply({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationLabel,
    bool requiresConfirmation = false,
  }) async {
    this.actionId = actionId;
    this.parameters = parameters;
    return expectedProject;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Workspace implements ProjectWorkspace {
  @override
  String get projectRoot => '/project';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Timeline',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
        CharacterCustomAnimationDefinition(
          id: 'jump',
          displayName: 'Saut',
          mode: CharacterCustomAnimationMode.directional,
        ),
      ],
    ),
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(id: 'elia', name: 'Élia', tilesetId: 'elia'),
    ],
  );
}
