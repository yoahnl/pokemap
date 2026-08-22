import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

/// BETA-CIN-083 — the dialogued pre-session survives packaging and offline
/// install.
///
/// The journey is worthless as a fixture if it only exists in an author
/// workspace: what the Hub plays is an exported copy. So the project is
/// authored through canonical actions, exported, its source deleted, and then
/// installed with no network and no author tree — and the pre-session Scene,
/// its Presentation, every cue binding and every outcome route are read back
/// out of the installed package.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fixture = NeutralCertificationGameFixture(dialoguedPreSession: true);

  test('the journey exports, loses its source and installs offline', () async {
    final root = await Directory.systemTemp.createTemp('cin083-package-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final workRoot = Directory(p.join(root.path, 'authoring'))
      ..createSync(recursive: true);
    final supportRoot = Directory(p.join(root.path, 'application-support'));
    final packageFile = File(
      p.join(root.path, 'night-watch-1.0.0.avelunegame'),
    );

    // Authored the same way every transport authors it: one declared sequence.
    final run = await const DialoguedPreSessionTransportParity().run(
      DialoguedPreSessionTransport.directApi,
      workRoot: workRoot,
    );
    expect(
      run.appliedActionIds,
      const DialoguedPreSessionFixture()
          .steps
          .map((step) => step.actionId)
          .toList(growable: false),
    );
    final authorRoot = Directory(
      p.join(workRoot.path, DialoguedPreSessionTransport.directApi.wireName),
    );

    final artifact = await const GamePackageExportService().exportToFile(
      projectRoot: authorRoot,
      profile: fixture.exportProfile,
      outputFile: packageFile,
    );
    expect(
      artifact.certification.isCertified,
      isTrue,
      reason: 'a dialogued pre-session must not cost the package its '
          'certification',
    );
    expect(artifact.manifest.gameId, fixture.gameId);

    // No author tree from here on: an installed runtime may not depend on it.
    await authorRoot.delete(recursive: true);
    expect(await authorRoot.exists(), isFalse);

    final progress = <GameInstallProgress>[];
    final installed = await GamePackageInstaller(
      supportRoot: supportRoot,
      inspector: GamePackageInspector(
        hostCompatibility: fixture.hostCompatibility,
      ),
      availableDiskBytes: (_) async => 1024 * 1024 * 1024,
      prepareSavesForUpdate: (_, __) async =>
          const SaveUpdatePreparation(rollbackSnapshotAvailable: true),
      loadSmoke: (stagedVersionRoot, manifest) async {
        // The smoke runs on the STAGED tree, so a journey that only survives
        // in the author workspace fails here rather than at play time.
        final project = await _readProject(stagedVersionRoot);
        expect(
          project.newGame.preSessionSceneId,
          DialoguedPreSessionFixture.sceneId,
        );
      },
    ).install(
      packageFile,
      source: GamePackageInstallSource.localExport,
      onProgress: progress.add,
    );

    expect(installed.game.gameId, fixture.gameId);
    expect(installed.receipt.packageSha256, artifact.packageSha256);
    expect(
      installed.receipt.treeSha256,
      artifact.manifest.content.treeSha256,
      reason: 'the installed tree is the exported tree, hash for hash',
    );
    expect(progress.last.stage, GameInstallStage.completed);

    // And the journey itself is intact in the installed copy.
    final project = await _readProject(
      Directory(
        p.join(
          supportRoot.path,
          'games',
          fixture.gameId,
          'versions',
          fixture.gameVersion,
        ),
      ),
    );
    final scene = project.scenes.singleWhere(
      (candidate) => candidate.id == DialoguedPreSessionFixture.sceneId,
    );
    final opening = scene.graph.nodes.singleWhere(
      (node) => node.id == DialoguedPreSessionFixture.openingNodeId,
    );
    final payload = opening.payload as ScenePresentationCinematicPayload;
    expect(
      payload.presentationCinematicId,
      DialoguedPreSessionFixture.cinematicId,
    );
    expect(
      payload.interactionCueBindings.map((binding) => binding.markerId).toSet(),
      <String>{
        DialoguedPreSessionFixture.pagesMarkerId,
        DialoguedPreSessionFixture.avatarMarkerId,
        DialoguedPreSessionFixture.nameMarkerId,
        DialoguedPreSessionFixture.confirmMarkerId,
        DialoguedPreSessionFixture.closingMarkerId,
      },
      reason: 'every cue binding survived export and install',
    );
    expect(
      <String>{
        for (final binding in payload.interactionCueBindings)
          for (final route in binding.outcomeRoutes)
            route.outcome.kind.wireName,
      },
      DialoguedPreSessionFixture.coveredOutcomeWireNames,
      reason: 'the four outcomes are readable from the installed package',
    );
    final cinematic = project.presentationCinematics.singleWhere(
      (asset) => asset.id == DialoguedPreSessionFixture.cinematicId,
    );
    expect(
      <String>{
        for (final track in cinematic.tracks)
          for (final clip in track.clips) clip.id,
      },
      contains(DialoguedPreSessionFixture.montageMarkerId),
      reason: 'the seek destination survived too, or the jump would resolve '
          'to nothing at play time',
    );

    // BETA-CIN-083's media criterion, read out of the INSTALLED package rather
    // than out of the authoring workspace: the variants and the single music
    // are what a player would actually get.
    final clips = <String, PresentationClip>{
      for (final track in cinematic.tracks)
        for (final clip in track.clips) clip.id: clip,
    };
    final backdrop =
        clips[DialoguedPreSessionFixture.backdropClipId]!
            as PresentationVisualClip;
    expect(
      backdrop.landscapeResourceId,
      DialoguedPreSessionFixture.backdropWideMediaId,
    );
    expect(
      backdrop.portraitResourceId,
      DialoguedPreSessionFixture.backdropTallMediaId,
    );

    final sharedOnly =
        clips[DialoguedPreSessionFixture.sharedOnlyClipId]!
            as PresentationVisualClip;
    expect(
      sharedOnly.landscapeResourceId,
      isNull,
      reason: 'this clip is the fallback case on purpose: no variant at all',
    );
    expect(sharedOnly.portraitResourceId, isNull);
    expect(
      sharedOnly.resourceId,
      DialoguedPreSessionFixture.backdropMediaId,
      reason: 'so both orientations resolve to the one available version',
    );

    final music =
        clips[DialoguedPreSessionFixture.musicClipId]! as PresentationAudioClip;
    expect(music.audioKind, PresentationAudioKind.music);
    expect(
      music.landscapeResourceId,
      isNull,
      reason: 'a music carries one shared source across orientations',
    );
    expect(music.portraitResourceId, isNull);
    expect(
      presentationAudioResourceForOrientation(
        music,
        PresentationAudioOrientation.landscape,
      ),
      presentationAudioResourceForOrientation(
        music,
        PresentationAudioOrientation.portrait,
      ),
      reason: 'the installed music resolves identically both ways',
    );

    // And the bytes travelled with it: the catalog is in the installed tree.
    expect(
      await File(
        p.join(
          supportRoot.path,
          'games',
          fixture.gameId,
          'versions',
          fixture.gameVersion,
          'project',
          'assets',
          '.pokemap-media.json',
        ),
      ).exists(),
      isTrue,
      reason: 'a clip pointing at a media the package does not carry would '
          'render nothing offline',
    );
  }, timeout: const Timeout(Duration(minutes: 6)));

  test('exporting twice from the same authoring yields the same hashes',
      () async {
    final root = await Directory.systemTemp.createTemp('cin083-determinism-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final hashes = <String>[];
    final treeHashes = <String>[];
    for (final attempt in <int>[1, 2]) {
      final workRoot = Directory(p.join(root.path, 'attempt-$attempt'))
        ..createSync(recursive: true);
      await const DialoguedPreSessionTransportParity().run(
        DialoguedPreSessionTransport.directApi,
        workRoot: workRoot,
      );
      final artifact = await const GamePackageExportService().exportToFile(
        projectRoot: Directory(
          p.join(
            workRoot.path,
            DialoguedPreSessionTransport.directApi.wireName,
          ),
        ),
        profile: fixture.exportProfile,
        outputFile: File(p.join(root.path, 'attempt-$attempt.avelunegame')),
      );
      hashes.add(artifact.packageSha256);
      treeHashes.add(artifact.manifest.content.treeSha256);
    }

    expect(
      treeHashes.first,
      treeHashes.last,
      reason: 'the authored content is deterministic: the same action sequence '
          'on the same seed must produce the same tree, or no hash in the '
          'package is worth comparing',
    );
    expect(hashes.first, hashes.last);
  }, timeout: const Timeout(Duration(minutes: 8)));
}

Future<ProjectManifest> _readProject(Directory versionRoot) async =>
    ProjectManifest.fromJson(
      jsonDecode(
        await File(
          p.join(versionRoot.path, 'project', 'project.json'),
        ).readAsString(),
      ) as Map<String, dynamic>,
    );
