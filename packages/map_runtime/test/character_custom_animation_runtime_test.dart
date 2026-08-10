import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('CharacterCustomAnimationRuntimeController', () {
    late _FakeActor actor;
    late bool actorPresent;
    late CharacterCustomAnimationRuntimeController controller;

    setUp(() {
      actor = _FakeActor(character: _character());
      actorPresent = true;
      controller = CharacterCustomAnimationRuntimeController(
        manifest: _manifest(),
        actorLookup: (actorId) =>
            actorPresent && actorId == actor.actorId ? actor : null,
      );
    });

    test('single clip completes deterministically and restores Base', () async {
      final future = controller.play(
        CharacterCustomAnimationRuntimeCommand(
          actorId: 'hero',
          definitionId: 'wave',
        ),
      );

      expect(actor.playedDefinitionIds, <String>['wave']);
      expect(actor.restoreCount, 0);
      controller.update(const Duration(milliseconds: 299));
      expect(actor.restoreCount, 0);
      controller.update(const Duration(milliseconds: 1));

      final result = await future;
      expect(result.status, CharacterCustomAnimationRuntimeStatus.completed);
      expect(actor.restoreCount, 1);
      expect(actor.lastRestoredFacing, EntityFacing.south);
    });

    test('directional definition resolves only the exact direction', () async {
      final future = controller.play(
        CharacterCustomAnimationRuntimeCommand(
          actorId: 'hero',
          definitionId: 'jump',
          direction: EntityFacing.east,
          playback: CharacterCustomAnimationPlayback.repeatCount(2),
        ),
      );

      expect(actor.lastClip?.direction, EntityFacing.east);
      controller.update(const Duration(milliseconds: 400));

      expect(
        (await future).status,
        CharacterCustomAnimationRuntimeStatus.completed,
      );
      expect(actor.lastRestoredFacing, EntityFacing.south);
    });

    test('actor, definition and clip failures are typed', () async {
      final missingActor = await controller.play(
        CharacterCustomAnimationRuntimeCommand(
          actorId: 'ghost',
          definitionId: 'wave',
        ),
      );
      final missingDefinition = await controller.play(
        CharacterCustomAnimationRuntimeCommand(
          actorId: 'hero',
          definitionId: 'unknown',
        ),
      );
      final missingClip = await controller.play(
        CharacterCustomAnimationRuntimeCommand(
          actorId: 'hero',
          definitionId: 'jump',
          direction: EntityFacing.north,
        ),
      );

      expect(
        missingActor.diagnosticCode,
        CharacterCustomAnimationRuntimeDiagnosticCode.actorAbsent,
      );
      expect(
        missingDefinition.diagnosticCode,
        CharacterCustomAnimationRuntimeDiagnosticCode.definitionAbsent,
      );
      expect(
        missingClip.diagnosticCode,
        CharacterCustomAnimationRuntimeDiagnosticCode.clipAbsent,
      );
    });

    test('definition mode rejects incoherent directions', () async {
      final singleWithDirection = await controller.play(
        CharacterCustomAnimationRuntimeCommand(
          actorId: 'hero',
          definitionId: 'wave',
          direction: EntityFacing.west,
        ),
      );
      final directionalWithoutDirection = await controller.play(
        CharacterCustomAnimationRuntimeCommand(
          actorId: 'hero',
          definitionId: 'jump',
        ),
      );

      expect(
        singleWithDirection.diagnosticCode,
        CharacterCustomAnimationRuntimeDiagnosticCode.directionNotAllowed,
      );
      expect(
        directionalWithoutDirection.diagnosticCode,
        CharacterCustomAnimationRuntimeDiagnosticCode.directionRequired,
      );
    });

    test('source fallback restores Base and completes explicitly', () async {
      actor.sourceAvailable = false;

      final result = await controller.play(
        CharacterCustomAnimationRuntimeCommand(
          actorId: 'hero',
          definitionId: 'wave',
          fallbackPolicy:
              CharacterCustomAnimationFallbackPolicy.restoreBaseAndComplete,
        ),
      );

      expect(
        result.status,
        CharacterCustomAnimationRuntimeStatus.fallbackApplied,
      );
      expect(
        result.diagnosticCode,
        CharacterCustomAnimationRuntimeDiagnosticCode.sourceUnavailable,
      );
      expect(actor.restoreCount, 1);
    });

    test('replace interruption completes old play and starts the next',
        () async {
      final first = controller.play(
        CharacterCustomAnimationRuntimeCommand(
          actorId: 'hero',
          definitionId: 'wave',
          playback: CharacterCustomAnimationPlayback.repeatCount(3),
        ),
      );
      final second = controller.play(
        CharacterCustomAnimationRuntimeCommand(
          actorId: 'hero',
          definitionId: 'wave',
        ),
      );

      expect(
        (await first).status,
        CharacterCustomAnimationRuntimeStatus.interrupted,
      );
      controller.update(const Duration(milliseconds: 300));
      expect(
        (await second).status,
        CharacterCustomAnimationRuntimeStatus.completed,
      );
      expect(actor.playedDefinitionIds, <String>['wave', 'wave']);
    });

    test('rejectIfBusy leaves active animation untouched', () async {
      final first = controller.play(
        CharacterCustomAnimationRuntimeCommand(
          actorId: 'hero',
          definitionId: 'wave',
          playback: CharacterCustomAnimationPlayback.repeatCount(2),
        ),
      );
      final rejected = await controller.play(
        CharacterCustomAnimationRuntimeCommand(
          actorId: 'hero',
          definitionId: 'wave',
          interruptionPolicy:
              CharacterCustomAnimationInterruptionPolicy.rejectIfBusy,
        ),
      );

      expect(
        rejected.diagnosticCode,
        CharacterCustomAnimationRuntimeDiagnosticCode.actorBusy,
      );
      controller.update(const Duration(milliseconds: 600));
      expect(
        (await first).status,
        CharacterCustomAnimationRuntimeStatus.completed,
      );
      expect(actor.playedDefinitionIds, <String>['wave']);
    });

    test('actor removal completes the pending command once', () async {
      final future = controller.play(
        CharacterCustomAnimationRuntimeCommand(
          actorId: 'hero',
          definitionId: 'wave',
        ),
      );

      actorPresent = false;
      controller.update(const Duration(milliseconds: 1));
      controller.update(const Duration(milliseconds: 500));

      final result = await future;
      expect(result.status, CharacterCustomAnimationRuntimeStatus.failed);
      expect(
        result.diagnosticCode,
        CharacterCustomAnimationRuntimeDiagnosticCode.actorRemoved,
      );
      expect(actor.restoreCount, 1);
    });
  });
}

final class _FakeActor implements CharacterCustomAnimationRuntimeActor {
  _FakeActor({required this.character});

  @override
  final ProjectCharacterEntry character;

  @override
  String get actorId => 'hero';

  @override
  EntityFacing get facing => EntityFacing.south;

  bool sourceAvailable = true;
  int restoreCount = 0;
  EntityFacing? lastRestoredFacing;
  CharacterCustomAnimationClip? lastClip;
  final List<String> playedDefinitionIds = <String>[];

  @override
  bool canPlayCustomAnimation(CharacterCustomAnimationClip clip) =>
      sourceAvailable;

  @override
  void playCustomAnimation(CharacterCustomAnimationClip clip) {
    lastClip = clip;
    playedDefinitionIds.add(clip.definitionId);
  }

  @override
  void restoreBase(EntityFacing facing) {
    restoreCount += 1;
    lastRestoredFacing = facing;
  }
}

ProjectManifest _manifest() {
  return ProjectManifest(
    name: 'Custom animation runtime',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
        CharacterCustomAnimationDefinition(
          id: 'wave',
          displayName: 'Wave',
          mode: CharacterCustomAnimationMode.single,
        ),
        CharacterCustomAnimationDefinition(
          id: 'jump',
          displayName: 'Jump',
          mode: CharacterCustomAnimationMode.directional,
        ),
      ],
    ),
  );
}

ProjectCharacterEntry _character() {
  return const ProjectCharacterEntry(
    id: 'hero_character',
    name: 'Hero',
    tilesetId: 'hero',
    customAnimations: <CharacterCustomAnimationClip>[
      CharacterCustomAnimationClip(
        definitionId: 'wave',
        sourceAssetId: 'wave_source',
        frames: <CharacterAnimationFrame>[
          CharacterAnimationFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 24, height: 32),
            durationMs: 100,
          ),
          CharacterAnimationFrame(
            source: TilesetSourceRect(x: 24, y: 0, width: 24, height: 32),
            durationMs: 200,
          ),
        ],
      ),
      CharacterCustomAnimationClip(
        definitionId: 'jump',
        direction: EntityFacing.east,
        sourceAssetId: 'jump_east_source',
        frames: <CharacterAnimationFrame>[
          CharacterAnimationFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 24, height: 32),
            durationMs: 200,
          ),
        ],
      ),
    ],
  );
}
