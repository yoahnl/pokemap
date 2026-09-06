import 'dart:io';

import 'package:map_runtime/map_runtime.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:pokemap_loader/main.dart' as runtime_host;

Future<void> main() async {
  MarionetteBinding.ensureInitialized();
  const configuredPath = String.fromEnvironment('MARIONETTE_PROJECT_PATH');
  if (configuredPath.isEmpty || !configuredPath.startsWith('/')) {
    throw StateError(
      'MARIONETTE_PROJECT_PATH must be an absolute project directory.',
    );
  }
  final projectFile = File('$configuredPath/project.json');
  if (!await projectFile.exists()) {
    throw StateError('The configured Player project does not exist.');
  }
  final resolvedPath = await projectFile.resolveSymbolicLinks();
  PlayableMapGame? game;
  registerMarionetteExtension(
    name: 'player.qaContext',
    description: 'Returns the launched project and observable Player state.',
    callback: (_) async {
      final current = game;
      final state = current?.gameStateSnapshot;
      final battle = current?.battleCommandOverlayListenable.value;
      return MarionetteExtensionResult.success({
        'projectFilePath': resolvedPath,
        'gameCreated': current != null,
        'loaded': current?.isLoaded ?? false,
        'paused': current?.paused,
        'inputContext': current?.inputAuthoritySnapshot.context.name,
        'dialogueTextSpeed': current?.dialogueTextSpeed.name,
        'reducedMotion': current?.reducedMotion,
        'textScale': current?.textScale,
        'mapId': state?.currentMapId,
        'position': state?.playerPosition.toJson(),
        'facing': state?.playerFacing.name,
        'metadata': state?.metadata,
        'battle': battle == null
            ? null
            : {
                'phase': battle.phase.name,
                'mode': battle.mode.name,
                'prompt': battle.prompt,
                'interactionsEnabled': battle.interactionsEnabled,
                'entries': battle.entries
                    .map((entry) => entry.primaryLabel)
                    .toList(),
              },
        'facts': state?.narrativeFactRuntimeState.overridesByFactId,
        'trainer': state?.trainerProfile.toJson(),
        'bag': state?.bag.toJson(),
        'rail': state?.railJourneyProgress.toJson(),
        'party': state?.party.members
            .map(
              (p) => {
                'speciesId': p.speciesId,
                'level': p.level,
                'hp': p.currentHp,
              },
            )
            .toList(),
      });
    },
  );
  registerMarionetteExtension(
    name: 'player.qaInput',
    description:
        'Sends one bounded controller press through the Player input API.',
    callback: (params) async {
      final current = game;
      if (current == null || !current.isLoaded) {
        throw StateError('The Player is not loaded.');
      }
      final control = RuntimeInputControl.values.byName(
        params['control'] ?? '',
      );
      final holdMs = int.parse(params['holdMs'] ?? '70');
      if (holdMs < 10 || holdMs > 300) {
        throw ArgumentError.value(holdMs, 'holdMs', 'Expected 10 to 300 ms.');
      }
      final accepted = current.handleRuntimeInputEvent(
        RuntimeInputEvent.press(control),
      );
      try {
        await Future<void>.delayed(Duration(milliseconds: holdMs));
      } finally {
        current.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
      }
      return MarionetteExtensionResult.success({'accepted': accepted});
    },
  );
  runtime_host.runRuntimeHost(
    initialProjectFilePath: resolvedPath,
    onGameChanged: (value) => game = value,
  );
}
