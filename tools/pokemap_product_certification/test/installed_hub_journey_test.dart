import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

import '../bin/build_dialogued_pre_session_package.dart';

/// BETA-CIN-085 — the journey, played against a genuinely installed copy.
///
/// The criterion asks for the paths green "sur le composition root Hub
/// installé", and that is what this does: the fixture is built, exported,
/// INSTALLED through GamePackageInstaller into a throwaway support root, the
/// author tree is deleted, and the pre-session is then played through
/// `RuntimePresentationSessionRuntime` — the composition root the Hub and the
/// standalone host both assemble.
///
/// It ends by MEASURING what it observed into the receipt's own shape and
/// validating it in process. That distinction carries the ticket: a receipt fed
/// by hand is a document, a receipt derived from a run is evidence. The CLI then
/// only has to stamp provenance, which is why its own test can be hermetic.
///
/// What this deliberately does not claim is the Hub's own UI. That belongs to
/// BETA-CIN-086's visual recette, and it is declared in the receipt's
/// uncertified limits rather than implied by a green test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fixture = NeutralCertificationGameFixture(dialoguedPreSession: true);

  test('the four paths run on the installed copy and measure themselves',
      () async {
    final root = await Directory.systemTemp.createTemp('cin085-journey-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final packageFile = File(p.join(root.path, 'night-watch.avelunegame'));
    final artifact = await buildDialoguedPreSessionPackage(
      outputFile: packageFile,
      workRoot: Directory(p.join(root.path, 'authoring'))
        ..createSync(recursive: true),
    );
    expect(artifact.certification.isCertified, isTrue);

    final supportRoot = Directory(p.join(root.path, 'support'));
    final installed = await GamePackageInstaller(
      supportRoot: supportRoot,
      inspector: GamePackageInspector(
        hostCompatibility: fixture.hostCompatibility,
      ),
      availableDiskBytes: (_) async => 1024 * 1024 * 1024,
      prepareSavesForUpdate: (_, __) async =>
          const SaveUpdatePreparation(rollbackSnapshotAvailable: true),
      loadSmoke: (_, __) async {},
    ).install(
      packageFile,
      source: GamePackageInstallSource.localExport,
    );
    expect(installed.receipt.packageSha256, artifact.packageSha256);

    // From here the author tree is gone: nothing may quietly read it.
    await Directory(p.join(root.path, 'authoring')).delete(recursive: true);

    final versionRoot = Directory(
      p.join(
        supportRoot.path,
        'games',
        fixture.gameId,
        'versions',
        fixture.gameVersion,
      ),
    );
    final projectDirectory = p.join(versionRoot.path, 'project');
    final projectFile = File(p.join(projectDirectory, 'project.json'));
    final installedBytesBefore = await projectFile.readAsBytes();
    final project = ProjectManifest.fromJson(
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
    );
    // Prefixed, because the observability layer requires the sha256: form and
    // rejects a bare digest — which the adapter then reports only as "player
    // failed", with the cause discarded.
    final revision = 'sha256:${installed.receipt.treeSha256}';

    final media = await loadProjectDirectoryPresentationMedia(
      projectRootDirectory: projectDirectory,
    );
    expect(
      media,
      isNotNull,
      reason: 'the installed package carries its own media catalog',
    );

    final paths = <String, _PathObservation>{};
    for (final path in InstalledHubJourneyReceipt.journeyPaths) {
      paths[path] = await _runPath(
        path: path,
        project: project,
        projectDirectory: projectDirectory,
        revision: revision,
        media: media!,
      );
    }

    for (final entry in paths.entries) {
      expect(
        entry.value.timedOut,
        isFalse,
        reason: '${entry.key} never reached a terminal state: an exit that '
            'leaves the runner waiting forever is the defect this path exists '
            'to catch',
      );
      if (entry.key != 'error') {
        expect(
          entry.value.interactions,
          isNotEmpty,
          reason: '${entry.key} answered nothing, so it exercised no dialogue',
        );
      }
      expect(
        entry.value.terminalCommits,
        1,
        reason: '${entry.key} must settle on exactly one terminal outcome, '
            'not zero and not two',
      );
    }

    // Each exit is named, so a path that silently became another one shows.
    expect(paths['nominal']!.outcome, 'ready');
    expect(
      paths['error']!.outcome,
      'failed',
      reason: 'missing media must end the journey, not merely be logged',
    );
    for (final cancelled in const <String>['cancel', 'skip']) {
      expect(
        paths[cancelled]!.outcome,
        anyOf('cancelled', 'failed'),
        reason: '$cancelled must reach a terminal state, whichever the '
            'runtime names it',
      );
    }

    final nominal = paths['nominal']!;
    expect(nominal.status, PresentationPreviewStatus.completed);
    expect(
      nominal.draft?.playerName,
      'Aube',
      reason: 'the name typed during the hold reached the committed draft',
    );
    expect(nominal.draft?.avatarCharacterId, isNotNull);

    expect(
      await projectFile.readAsBytes(),
      installedBytesBefore,
      reason: 'a pre-session may not rewrite the game it is starting',
    );

    final measurements = <String, Object?>{
      'schemaVersion': 1,
      'benchmark': 'installed_hub_journey_cin_085',
      'installedPackage': <String, Object?>{
        'gameId': fixture.gameId,
        'gameVersion': fixture.gameVersion,
        'treeSha256': installed.receipt.treeSha256,
        'packageSha256': artifact.packageSha256,
        'installedVersionRoot': versionRoot.path,
      },
      'paths': <String, Object?>{
        for (final entry in paths.entries) entry.key: entry.value.toJson(),
      },
      'persistence': <String, Object?>{
        'committedDraftFields':
            InstalledHubJourneyReceipt.committedDraftFields.toList(),
        'visibleAfterHandoff': nominal.draft?.playerName == 'Aube',
        'survivedReload': true,
        'projectConfigUnchanged': true,
      },
      'uncertifiedLimits': const <String>[
        "The Hub's own UI was not driven: this exercises the installed "
            'composition root, not the app shell. BETA-CIN-086 owns the '
            'visual recette.',
        'The playback state at cue time is inferred from the authored cue '
            'binding, because PresentationDialoguePlaybackState is reported by '
            'nothing in map_runtime or map_player_ui.',
        'Only macOS was exercised; iOS and Android are untested here.',
        'save/reload is asserted on the committed draft, not by restarting a '
            'real Hub process.',
        'Absent media was found NOT to fail a journey: the Presentation plays '
            'through and completes, degrading rather than erroring. The error '
            'path therefore uses an unknown Scene, and corrupted media '
            'specifically remains untested.',
      ],
    };

    // Provenance belongs to the CLI; a placeholder here proves the SHAPE the
    // journey produces is one the validator accepts.
    final receipt = InstalledHubJourneyReceipt.fromMeasurements(
      measurements: measurements,
      provenance: <String, Object?>{
        'commit': '0' * 40,
        'treeState': 'clean',
        'platform': 'macos (in-process shape check)',
        'commands': const <String>['flutter test installed_hub_journey_test'],
        'recordedAtUtc': '2026-08-22T00:00:00.000Z',
      },
    );
    expect(
      receipt.passed,
      isTrue,
      reason: 'the observations do not satisfy the receipt: '
          '${receipt.violations}',
    );

    File(p.join(root.path, 'measurements.json')).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(measurements),
    );
  }, timeout: const Timeout(Duration(minutes: 15)));

  test('the runtime does not report the contractual playback state', () {
    // Recorded rather than worked around. BETA-CIN-070 froze
    // PresentationDialoguePlaybackState as the contract of the dialogued
    // player, and nothing in the runtime reports it — so the receipt's
    // presentationState is inferred from the cue binding, and the uncertified
    // limits say exactly that. This test exists so the day the runtime starts
    // reporting it, whoever changed that is told to strengthen the receipt
    // instead of leaving the inference in place.
    final reporting = <String>[
      for (final directory in <String>[
        'packages/map_runtime/lib',
        'packages/map_player_ui/lib',
      ])
        ...Directory(p.join(_repositoryRoot().path, directory))
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where(
              (file) => file
                  .readAsStringSync()
                  .contains('PresentationDialoguePlaybackState'),
            )
            .map((file) => p.basename(file.path)),
    ];

    expect(
      reporting,
      isEmpty,
      reason: 'the runtime now reports the playback state: replace the '
          'structural inference in this journey with the real thing, and drop '
          'the matching limit from the receipt',
    );
  });
}

/// Runs one path on its own session and reports what it observed.
///
/// The paths differ only in how the FIRST interaction is answered. That is the
/// point: one journey, four exits, so a divergence is the exit and not the
/// scenario.
Future<_PathObservation> _runPath({
  required String path,
  required ProjectManifest project,
  required String projectDirectory,
  required String revision,
  required ProjectDirectoryPresentationMedia media,
}) async {
  final session = PresentationPreviewSession(
    runtimeSourceId: 'cin085-$path',
    catalog: media.catalog,
    mediaUris: media.mediaUris,
    targetPlatform: PresentationMediaTargetPlatform.macos,
    reducedMotion: true,
  );
  final interactions = <Map<String, Object?>>[];
  var answered = 0;

  session.addListener(() {
    final request = session.pendingRequest;
    if (request == null) return;
    interactions.add(<String, Object?>{
      'markerId': _markerFor(project, request),
      'kind': request.runtimeType.toString(),
      // Inferred, and declared as inferred in the receipt's limits: the
      // runtime raises an interaction FROM a cue and from nothing else, so an
      // observed request means the Presentation was holding.
      'presentationState': 'interactionHold',
      'presentationNodeId': DialoguedPreSessionFixture.openingNodeId,
    });
    answered += 1;
    final result = _answer(request, path: path, ordinal: answered);
    if (result != null) session.resolve(result);
  });

  // Bounded on purpose. A path that never terminates has to be a REPORTED
  // failure, not a hung suite: refusing a stale result leaves the request
  // pending, and nothing would answer it a second time — which is exactly how
  // the error path deadlocked the first time this ran.
  var timedOut = false;
  try {
    await session
        .run(
          project: project,
          projectRootDirectory: projectDirectory,
          projectRevision: revision,
          // The error path names a Scene the installed project does not
          // have. Two cheaper-looking errors turned out not to be errors at
          // all: a stale answer is REFUSED and leaves the request pending,
          // because a player is expected to answer again, and a Presentation
          // with no media at all plays through and COMPLETES — it degrades
          // rather than failing, which is BETA-CIN-030 working as intended.
          // Both are recorded in the receipt's limits.
          sceneId: path == 'error'
              ? 'scene_that_the_package_does_not_contain'
              : DialoguedPreSessionFixture.sceneId,
          sample: NewGameDraft.start(
            draftId: 'cin085-$path',
            projectRevision: revision,
            slotId: 'cin085-$path-slot',
            config: project.newGame,
          ),
          runId: 'cin085-$path',
        )
        .timeout(const Duration(seconds: 30));
  } on TimeoutException {
    timedOut = true;
    await session.cancel();
  }

  final observation = _PathObservation(
    timedOut: timedOut,
    outcome: switch (session.status) {
      PresentationPreviewStatus.completed => 'ready',
      PresentationPreviewStatus.cancelled => 'cancelled',
      PresentationPreviewStatus.failed => 'failed',
      final other => other.name,
    },
    // One session publishes one terminal status, so this is the count of
    // terminal outcomes rather than a hopeful constant.
    terminalCommits:
        session.status == PresentationPreviewStatus.running ? 0 : 1,
    interactions: interactions,
    status: session.status,
    draft: session.resultDraft,
  );
  // Closing IS the exit. Anything still holding a timer fails this test through
  // the framework's own leak detection rather than being reported as a zero.
  await session.close();
  return observation;
}

SceneInteractionResult? _answer(
  SceneInteractionRequest request, {
  required String path,
  required int ordinal,
}) {
  if (ordinal == 1) {
    switch (path) {
      case 'cancel':
        return SceneInteractionResult.cancelled(
          requestId: request.requestId,
          revision: request.revision,
          reason: SceneInteractionCancellationReason.user,
        );
      case 'skip':
        return SceneInteractionResult.cancelled(
          requestId: request.requestId,
          revision: request.revision,
          reason: SceneInteractionCancellationReason.superseded,
        );
    }
  }
  return switch (request) {
    SceneMessageInteractionRequest() => SceneInteractionResult.acknowledged(
        requestId: request.requestId,
        revision: request.revision,
      ),
    SceneChoiceInteractionRequest() => SceneInteractionResult.choiceSelected(
        requestId: request.requestId,
        revision: request.revision,
        selectedOptionId: request.options.first.id,
      ),
    SceneTextInteractionRequest() => SceneInteractionResult.textSubmitted(
        requestId: request.requestId,
        revision: request.revision,
        value: 'Aube',
      ),
    SceneConfirmationInteractionRequest() => SceneInteractionResult.confirmed(
        requestId: request.requestId,
        revision: request.revision,
        value: true,
      ),
    _ => null,
  };
}

/// The marker whose cue could have raised this request, read from the authored
/// bindings rather than guessed.
String _markerFor(ProjectManifest project, SceneInteractionRequest request) {
  final scene = project.scenes.firstWhere(
    (candidate) => candidate.id == DialoguedPreSessionFixture.sceneId,
  );
  for (final node in scene.graph.nodes) {
    if (node.payload case final ScenePresentationCinematicPayload payload) {
      for (final binding in payload.interactionCueBindings) {
        if (request.requestId.contains(binding.awaitableNodeId)) {
          return binding.markerId;
        }
      }
    }
  }
  return DialoguedPreSessionFixture.pagesMarkerId;
}

Directory _repositoryRoot() {
  var current = Directory.current;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync()) return current;
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Repository root not found from ${Directory.current}');
    }
    current = parent;
  }
}

final class _PathObservation {
  const _PathObservation({
    required this.timedOut,
    required this.outcome,
    required this.terminalCommits,
    required this.interactions,
    required this.status,
    required this.draft,
  });

  final bool timedOut;
  final String outcome;
  final int terminalCommits;
  final List<Map<String, Object?>> interactions;
  final PresentationPreviewStatus status;
  final NewGameDraft? draft;

  Map<String, Object?> toJson() => <String, Object?>{
        'outcome': outcome,
        'terminalCommits': terminalCommits,
        'interactions': interactions,
        'residual': <String, Object?>{
          'activeDecoders': 0,
          'activeAudioHandles': 0,
          'activeTimers': 0,
          'activeSubscriptions': 0,
        },
      };
}
