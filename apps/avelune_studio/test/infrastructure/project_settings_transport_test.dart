import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../game_memory/game_memory_catalog_fixture.dart';
import '../support/pokemon_move_recipe_transport_owner_fixture.dart'
    show largeRecipeWav;
import '../support/transport_history.dart';

void main() {
  final conflict = throwsA(
    isA<MapWorkspaceFailure>().having(
      (failure) => failure.problem,
      'problem',
      MapWorkspaceProblem.conflict,
    ),
  );
  for (final catalog in [false, true]) {
    final storage = catalog ? 'working catalog' : 'manifest';

    test(
      'Surf and field ability settings persist independently with revision conflicts on $storage',
      () async {
        final session = await openGameMemoryCatalog(
          catalog: catalog,
          prepared: false,
        );
        final settings = LocalMapWorkspaceAdapter();
        await settings.loadCatalog(session);
        final before = await settings.loadSurf(session);
        const surf = ProjectSurfSettings(
          requiresKnownMove: false,
          accessMode: ProjectSurfAccessMode.always,
          speedCellsPerSecond: 6,
        );
        final saved = await settings.saveSurf(session, surf, before.revision);
        expect(saved.revision, isNot(before.revision));
        await expectLater(
          settings.saveSurf(session, null, before.revision),
          conflict,
        );

        final cs = await settings.saveFieldAbilityId(
          session,
          'rock_climb',
          false,
          saved.revision,
        );
        expect(cs.configuration!.disabledAbilityIds, {'rock_climb'});
        await expectLater(
          settings.saveFieldAbilityId(
            session,
            'rock_climb',
            true,
            saved.revision,
          ),
          conflict,
        );
        final fresh = LocalMapWorkspaceAdapter();
        expect((await fresh.loadSurf(session)).configuration, surf);
        expect(
          (await fresh.loadFieldAbilities(session))
              .configuration!
              .disabledAbilityIds,
          {'rock_climb'},
        );
        expect(
          await transportActionHistory(session),
          unorderedEquals(['surf.configure', 'field_ability.configure']),
        );
      },
    );

    test(
      'audio adoption reuses the source and cue changes survive a fresh adapter on $storage',
      () async {
        final session = await openGameMemoryCatalog(
          catalog: catalog,
          prepared: false,
        );
        final wav = largeRecipeWav();
        final artifact = ContentArtifactRef.fromBytes(
          wav,
          mediaType: 'application/octet-stream',
        );
        final source = AssetRecord(
          id: 'legacy-bell',
          logicalPath: 'assets/audio/bell.wav',
          artifact: artifact,
        );
        final blob = File(
          '${session.directoryPath}/${assetBlobStorageKey(artifact)}',
        );
        await blob.parent.create(recursive: true);
        await blob.writeAsBytes(wav);
        final catalogFile = File(
          '${session.directoryPath}/$assetCatalogStorageKey',
        );
        final originals = utf8.encode(
          jsonEncode(AssetCatalog(records: [source]).toJson()),
        );
        await catalogFile.writeAsBytes(originals);
        final settings = LocalMapWorkspaceAdapter();
        await settings.loadCatalog(session);
        final before = await settings.loadAudio(session);
        final adopted = await settings.adoptAudioAsset(
          session,
          source.id,
          'bell',
          'Cloche',
          before.revision,
        );
        final duplicate = await settings.adoptAudioAsset(
          session,
          source.id,
          'duplicate',
          'Copie',
          adopted.revision,
        );
        expect(duplicate.entry.id, 'bell');
        expect(duplicate.entry.label, 'Cloche');
        final cue = ProjectSoundBinding(
          source: ProjectSoundSource.custom,
          mediaId: adopted.entry.id,
          gain: .4,
        );
        final saved = await settings.saveAudioCue(
          session,
          ProjectSoundCue.uiConfirm,
          cue,
          duplicate.revision,
        );
        expect(saved.revision, isNot(duplicate.revision));
        await expectLater(
          settings.adoptAudioAsset(
            session,
            source.id,
            'stale',
            'Ancienne cloche',
            duplicate.revision,
          ),
          conflict,
        );
        await expectLater(
          settings.saveAudioCue(
            session,
            ProjectSoundCue.uiConfirm,
            null,
            duplicate.revision,
          ),
          conflict,
        );
        final fresh = LocalMapWorkspaceAdapter();
        expect(
          (await fresh.loadAudio(session))
              .configuration!
              .cues[ProjectSoundCue.uiConfirm],
          cue,
        );
        expect(
          (await fresh.queryAudio(session)).entries.map((entry) => entry.id),
          ['bell'],
        );
        final resolved = await fresh.resolveAudio(session, 'bell');
        expect(resolved.mimeType, 'audio/wav');
        expect(await File(resolved.path).readAsBytes(), wav);
        expect(await catalogFile.readAsBytes(), originals);
        expect(
          await transportActionHistory(session),
          unorderedEquals([
            'project.audio.media.adopt_asset',
            'project.audio.cue.configure',
          ]),
        );
      },
    );
  }
}
