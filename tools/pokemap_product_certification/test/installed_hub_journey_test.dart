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
/// The criterion says the paths must be green "sur le composition root Hub
/// installé", and that is what this does: the fixture is built, exported,
/// INSTALLED through GamePackageInstaller into a throwaway support root, and
/// then played through `RuntimePresentationSessionRuntime` — the same
/// composition root the Hub and the standalone host assemble. The author
/// workspace is deleted before the journey starts, so nothing can quietly read
/// it.
///
/// What this deliberately does NOT claim is the Hub's own UI. That is 086's
/// visual recette, and it is declared in the receipt's uncertified limits
/// rather than implied by a green test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fixture = NeutralCertificationGameFixture(dialoguedPreSession: true);

  test('the dialogued journey runs on the installed copy', () async {
    final root = await Directory.systemTemp.createTemp('cin085-journey-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    // 1. Build and export the fixture exactly as the CLI does.
    final packageFile = File(p.join(root.path, 'night-watch.avelunegame'));
    final artifact = await buildDialoguedPreSessionPackage(
      outputFile: packageFile,
      workRoot: Directory(p.join(root.path, 'authoring'))
        ..createSync(recursive: true),
    );
    expect(artifact.certification.isCertified, isTrue);

    // 2. Install it. No author tree is consulted from here on.
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
    final projectFile = File(
      p.join(versionRoot.path, 'project', 'project.json'),
    );
    expect(await projectFile.exists(), isTrue);
    final installedBytesBefore = await projectFile.readAsBytes();
    final project = ProjectManifest.fromJson(
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
    );

    // 3. Play the pre-session through the shared composition root, answering
    //    every cue the way the reference journey does.
    // The media has to come from the INSTALLED tree: the fixture's
    // Presentation references four assets, and an empty catalog makes the
    // player fail rather than silently render nothing.
    final media = await loadProjectDirectoryPresentationMedia(
      projectRootDirectory: p.join(versionRoot.path, 'project'),
    );
    expect(
      media,
      isNotNull,
      reason: 'the installed package carries its own media catalog',
    );
    final session = PresentationPreviewSession(
      runtimeSourceId: 'cin085-installed-journey',
      catalog: media!.catalog,
      mediaUris: media.mediaUris,
      targetPlatform: PresentationMediaTargetPlatform.macos,
      reducedMotion: true,
    );
    addTearDown(session.close);

    final observed = <_ObservedInteraction>[];
    session.addListener(() {
      final request = session.pendingRequest;
      if (request == null) return;
      observed.add(_ObservedInteraction(request));
      final result = _answer(request);
      if (result != null) session.resolve(result);
    });

    await session.run(
      project: project,
      projectRootDirectory: p.join(versionRoot.path, 'project'),
      projectRevision: 'sha256:${installed.receipt.treeSha256}',
      sceneId: DialoguedPreSessionFixture.sceneId,
      sample: NewGameDraft.start(
        draftId: 'cin085',
        projectRevision: 'sha256:${installed.receipt.treeSha256}',
        slotId: 'cin085-slot',
        config: project.newGame,
      ),
      runId: 'cin085-nominal',
    );

    expect(
      session.failure,
      isNull,
      reason: 'the nominal path must complete on the installed copy',
    );
    expect(session.status, PresentationPreviewStatus.completed);

    final draft = session.resultDraft;
    expect(draft, isNotNull);
    expect(
      draft!.playerName,
      isNotNull,
      reason: 'the name the player typed reached the committed draft',
    );

    // 4. Every cue of the reference journey was answered, in order.
    expect(
      observed.length,
      greaterThanOrEqualTo(4),
      reason: 'pages, avatar, name and confirmation at the very least — '
          'observed ${observed.map((entry) => entry.kind).toList()}',
    );

    // 5. The installed project is untouched: a pre-session may not rewrite the
    //    game it is starting.
    expect(
      await projectFile.readAsBytes(),
      installedBytesBefore,
      reason: 'the journey mutated the installed project config',
    );
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('the runtime does not report the contractual playback state', () {
    // Recorded rather than worked around. BETA-CIN-070 froze
    // PresentationDialoguePlaybackState as the contract of the dialogued
    // player, and nothing in map_runtime or map_player_ui reports it: grep it
    // and the only hits are map_core's own declaration and its own test. So a
    // receipt cannot say "the cue fired while interactionHold" on the runtime's
    // authority — the journey infers it structurally, from the cue binding, and
    // the receipt's uncertified limits must say so.
    //
    // This test exists so the day the runtime starts reporting it, someone is
    // told to strengthen the receipt instead of leaving the inference in place.
    final runtimeSources = <File>[
      for (final directory in <String>[
        'packages/map_runtime/lib',
        'packages/map_player_ui/lib',
      ])
        ...Directory(p.join(_repositoryRoot().path, directory))
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart')),
    ];
    final reporting = runtimeSources
        .where(
          (file) => file
              .readAsStringSync()
              .contains('PresentationDialoguePlaybackState'),
        )
        .map((file) => p.basename(file.path))
        .toList(growable: false);

    expect(
      reporting,
      isEmpty,
      reason: 'the runtime now reports the playback state: replace the '
          'structural inference in the CIN-085 journey with the real thing, '
          'and drop the limit from the receipt',
    );
  });
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

/// Answers a request the way the reference journey does: read the pages, pick
/// the first avatar, type a name, confirm it, decline the closing offer.
SceneInteractionResult? _answer(SceneInteractionRequest request) {
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

final class _ObservedInteraction {
  _ObservedInteraction(this.request);

  final SceneInteractionRequest request;

  String get kind => request.runtimeType.toString();
}
