import 'package:image/image.dart' as image;
import 'package:avelune_studio/features/project_audio/application/project_audio_controller.dart';
import 'package:avelune_studio/features/project_cs/application/project_cs_controller.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_audio_panel.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_cs_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';

import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_workshop_reader.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_surf_panel.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  for (final storage in [
    ProjectSessionStorage.manifest,
    ProjectSessionStorage.workingCatalog,
  ]) {
    test(
      'configuration-only CS persist by ID without map reads for $storage',
      () async {
        final root = await Directory.systemTemp.createTemp('eleven-cs-');
        addTearDown(() => root.delete(recursive: true));
        const project = ProjectManifest(
          name: 'Eleven CS',
          maps: [],
          tilesets: [],
          settings: ProjectSettings(
            surf: ProjectSurfSettings(speedCellsPerSecond: 6),
          ),
        );
        if (storage == ProjectSessionStorage.workingCatalog) {
          final store = await CatalogStorageStore.open(projectRoot: root.path);
          await WorkingProjectCatalog.create(
            store: store,
            projectId: 'eleven',
            project: project,
          );
        } else {
          await File('${root.path}/project.json')
              .writeAsString(jsonEncode(project.toJson()));
        }
        final session = ProjectSession(
          sessionId: root.path,
          name: 'Eleven CS',
          directoryPath: root.path,
          storage: storage,
        );
        final reader = _Reader();
        final adapter = LocalMapWorkspaceAdapter(reader: reader);
        if (storage == ProjectSessionStorage.manifest) {
          await adapter.loadProject(session);
        } else {
          await adapter.loadCatalog(session);
        }
        final owner = ProjectCsController(session: session, port: adapter);
        addTearDown(owner.dispose);
        await owner.open();
        reader.paths.clear();
        owner.setEnabledId('rock_climb', false);
        owner.setEnabledId('defog', false);
        expect(reader.paths, isEmpty);
        expect(await owner.save(), isTrue, reason: owner.error);
        final reopened = await LocalMapWorkspaceAdapter().loadFieldAbilities(
          session,
        );
        expect(reopened.configuration!.disabledAbilityIds, {
          'rock_climb',
          'defog',
        });
        owner.setEnabledId('rock_climb', true);
        expect(await owner.save(), isTrue, reason: owner.error);
        expect(
          (await LocalMapWorkspaceAdapter().loadFieldAbilities(session))
              .configuration!
              .disabledAbilityIds,
          {'defog'},
        );
        expect(
          (await adapter.loadSurf(session)).configuration!.speedCellsPerSecond,
          6,
        );
        expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
      },
    );
  }

  for (final storage in [
    ProjectSessionStorage.manifest,
    ProjectSessionStorage.workingCatalog,
  ]) {
    test(
      'legacy AssetCatalog audio adopts the same blob once for $storage',
      () async {
        final root = await Directory.systemTemp.createTemp('legacy-audio-');
        addTearDown(() => root.delete(recursive: true));
        const project = ProjectManifest(
          name: 'Historical audio',
          maps: [],
          tilesets: [],
        );
        if (storage == ProjectSessionStorage.workingCatalog) {
          final store = await CatalogStorageStore.open(projectRoot: root.path);
          await WorkingProjectCatalog.create(
            store: store,
            projectId: 'historical',
            project: project,
          );
        } else {
          await File('${root.path}/project.json')
              .writeAsString(jsonEncode(project.toJson()));
        }
        final artifact = ContentArtifactRef.fromBytes(
          _audioWav(),
          mediaType: 'application/octet-stream',
        );
        final source = File('${root.path}/${assetBlobStorageKey(artifact)}');
        await source.parent.create(recursive: true);
        await source.writeAsBytes(_audioWav());
        final assetCatalog = File('${root.path}/$assetCatalogStorageKey');
        await assetCatalog.writeAsString(
          jsonEncode(
            AssetCatalog(
              records: [
                AssetRecord(
                  id: 'old-bell',
                  logicalPath: 'assets/audio/historical-bell.wav',
                  artifact: artifact,
                ),
              ],
            ).toJson(),
          ),
        );
        final originalAssets = await assetCatalog.readAsBytes();
        final originalBlob = await source.readAsBytes();
        final session = ProjectSession(
          sessionId: root.path,
          name: 'Historical audio',
          directoryPath: root.path,
          storage: storage,
        );
        final reader = _Reader();
        final adapter = LocalMapWorkspaceAdapter(reader: reader);
        if (storage == ProjectSessionStorage.manifest) {
          await adapter.loadProject(session);
        } else {
          await adapter.loadCatalog(session);
        }
        final state = await adapter.loadAudio(session);
        reader.paths.clear();
        expect((await adapter.queryAudio(session)).entries, isEmpty);
        final legacy = await adapter.queryLegacyAudio(session);
        expect(legacy.entries.single.id, 'old-bell');
        expect(legacy.entries.single.label, 'historical-bell.wav');
        final adopted = await adapter.adoptAudioAsset(
          session,
          'old-bell',
          'adopted-bell',
          'Ancienne cloche',
          state.revision,
        );
        expect(adopted.entry.id, 'adopted-bell');
        expect(adopted.entry.label, 'Ancienne cloche');
        final mediaFile = File('${root.path}/$projectMediaCatalogStorageKey');
        final firstMediaBytes = await mediaFile.readAsBytes();
        final adoptionReads = [...reader.paths];
        reader.paths.clear();
        final duplicate = await adapter.adoptAudioAsset(
          session,
          'old-bell',
          'unwanted-duplicate',
          'Ignored label',
          adopted.revision,
        );
        expect(reader.paths, isNot(contains(assetBlobStorageKey(artifact))));
        expect(duplicate.entry.id, 'adopted-bell');
        expect(duplicate.entry.label, 'Ancienne cloche');
        expect(await mediaFile.readAsBytes(), firstMediaBytes);
        expect(await assetCatalog.readAsBytes(), originalAssets);
        expect(await source.readAsBytes(), originalBlob);
        final catalog = decodeProjectMediaCatalogBytes(firstMediaBytes);
        expect(catalog.entries, hasLength(1));
        expect(catalog.entries.single.sourceAssetId, 'old-bell');
        expect(
          catalog.entries.single.technicalMetadata!.durationMilliseconds,
          1000,
        );
        final resolved = await adapter.resolveAudio(
          session,
          duplicate.entry.id,
        );
        expect(resolved.path, source.path);
        expect(resolved.mimeType, 'audio/wav');
        expect(await File(resolved.path).readAsBytes(), originalBlob);
        await adapter.saveAudioCue(
          session,
          ProjectSoundCue.uiConfirm,
          ProjectSoundBinding(
            source: ProjectSoundSource.custom,
            mediaId: duplicate.entry.id,
          ),
          duplicate.revision,
        );
        final reopened = await LocalMapWorkspaceAdapter().loadAudio(session);
        expect(
          reopened.configuration!.cues[ProjectSoundCue.uiConfirm]!.mediaId,
          'adopted-bell',
        );
        await assetCatalog.writeAsString(
          jsonEncode(
            AssetCatalog(
              records: [
                AssetRecord(
                  id: 'old-bell',
                  logicalPath: 'assets/audio/historical-bell.wav',
                  artifact: ContentArtifactRef(
                    digest: artifact.digest,
                    mediaType: 'audio/ogg',
                    byteLength: artifact.byteLength,
                  ),
                ),
              ],
            ).toJson(),
          ),
        );
        await expectLater(
          adapter.resolveAudio(session, duplicate.entry.id),
          throwsStateError,
        );
        await assetCatalog.writeAsBytes(originalAssets);
        await source.writeAsBytes(
          originalBlob.sublist(0, originalBlob.length - 1),
        );
        await expectLater(
          adapter.resolveAudio(session, duplicate.entry.id),
          throwsStateError,
        );
        final corrupted = List<int>.of(originalBlob)
          ..[originalBlob.length - 1] ^= 1;
        await source.writeAsBytes(corrupted);
        await expectLater(
          adapter.resolveAudio(session, duplicate.entry.id),
          throwsA(
            isA<ProjectAudioSourceException>().having(
              (error) => error.code,
              'code',
              'project_audio.source_digest_mismatch',
            ),
          ),
        );
        await source.writeAsBytes(originalBlob);
        final png = image.encodePng(image.Image(width: 1, height: 1));
        final pngArtifact = ContentArtifactRef.fromBytes(
          png,
          mediaType: 'application/octet-stream',
        );
        await File('${root.path}/${assetBlobStorageKey(pngArtifact)}')
            .writeAsBytes(png);
        await assetCatalog.writeAsString(
          jsonEncode(
            AssetCatalog(
              records: [
                AssetRecord(
                  id: 'old-bell',
                  logicalPath: 'assets/audio/historical-bell.wav',
                  artifact: pngArtifact,
                ),
              ],
            ).toJson(),
          ),
        );
        final forged = ProjectMediaAsset.fromJson({
          ...catalog.entries.single.toJson(),
          'technicalMetadata': {
            ...catalog.entries.single.technicalMetadata!.toJson(),
            'sizeBytes': png.length,
          },
        });
        await mediaFile.writeAsBytes(
          encodeProjectMediaCatalogBytes(
            ProjectMediaCatalog(entries: [forged]),
          ),
        );
        await expectLater(
          adapter.resolveAudio(session, duplicate.entry.id),
          throwsA(
            isA<ProjectAudioSourceException>().having(
              (error) => error.code,
              'code',
              'presentation_media.mime_mismatch',
            ),
          ),
        );
        expect(
          [
            ...adoptionReads,
            ...reader.paths,
          ].where((path) => path.startsWith('maps/')),
          isEmpty,
        );
      },
    );
  }

  testWidgets(
    'CS and Son widgets persist their drafts through canonical actions and reopen',
    (tester) async {
      final fixture = (await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp('settings-widget-');
        final store = await CatalogStorageStore.open(projectRoot: root.path);
        await WorkingProjectCatalog.create(
          store: store,
          projectId: 'settings-widget',
          project: const ProjectManifest(
            name: 'Settings',
            maps: [],
            tilesets: [],
          ),
        );
        final oldArtifact = ContentArtifactRef.fromBytes(
          _audioWav(),
          mediaType: 'audio/wav',
        );
        final oldFile = File(
          '${root.path}/${assetBlobStorageKey(oldArtifact)}',
        );
        await oldFile.parent.create(recursive: true);
        await oldFile.writeAsBytes(_audioWav());
        await File('${root.path}/$assetCatalogStorageKey').writeAsString(
          jsonEncode(
            AssetCatalog(
              records: [
                AssetRecord(
                  id: 'widget-old',
                  logicalPath: 'assets/audio/old-bell.wav',
                  artifact: oldArtifact,
                ),
              ],
            ).toJson(),
          ),
        );
        final session = ProjectSession(
          sessionId: root.path,
          name: 'Settings',
          directoryPath: root.path,
          storage: ProjectSessionStorage.workingCatalog,
        );
        final reader = _Reader();
        final adapter = LocalMapWorkspaceAdapter(reader: reader);
        await adapter.loadCatalog(session);
        final audio = ProjectAudioController(session: session, port: adapter);
        final cs = ProjectCsController(
          session: session,
          port: adapter,
          onRevisionChanged: audio.adoptRevision,
        );
        final surf = ProjectSurfController(
          session: session,
          port: adapter,
          dimension: ProjectDimension.threeD,
        );
        await cs.open();
        await surf.open();
        await audio.open();
        await audio.loadLegacyLibrary();
        return (
          root: root,
          session: session,
          reader: reader,
          cs: cs,
          surf: surf,
          audio: audio,
        );
      }))!;
      addTearDown(fixture.cs.dispose);
      addTearDown(fixture.surf.dispose);
      addTearDown(fixture.audio.dispose);
      addTearDown(() => fixture.root.delete(recursive: true));
      Widget app(Widget child) => MaterialApp(
        theme: studioTheme(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );
      await tester.pumpWidget(
        app(
          ProjectCsPanel(
            owner: fixture.cs,
            surf: fixture.surf,
            settings: const ProjectSettings(dimension: ProjectDimension.threeD),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final reads = fixture.reader.paths.length;
      await tester.ensureVisible(find.byKey(const ValueKey('cs-dive')));
      await tester.tap(find.byKey(const ValueKey('cs-dive')));
      await tester.pump();
      for (final id in ['rock_climb', 'defog']) {
        final row = find.byKey(ValueKey('cs-$id'));
        await tester.ensureVisible(row);
        await tester.tap(row);
        await tester.pump();
      }
      expect(fixture.cs.preview.value.disabledAbilityIds, {
        'dive',
        'rock_climb',
        'defog',
      });
      expect(fixture.reader.paths.length, reads);
      await tester.ensureVisible(find.byKey(const ValueKey('save-project-cs')));
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('save-project-cs')));
        while (fixture.cs.saving) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();
      expect(fixture.cs.error, isNull);
      expect(fixture.cs.dirty, isFalse);
      await tester.pumpWidget(app(ProjectAudioPanel(owner: fixture.audio)));
      await tester.pumpAndSettle();
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('project-audio-source-ui.confirm')),
          )
          .onChanged!('builtin');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('save-project-audio')),
      );
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('save-project-audio')));
        while (fixture.audio.saving) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();
      expect(fixture.audio.error, isNull);
      expect(fixture.audio.dirty, isFalse);
      final adopt = find.byKey(
        const ValueKey('adopt-project-audio-widget-old'),
      );
      await tester.ensureVisible(adopt);
      await tester.runAsync(() async {
        await tester.tap(adopt);
        while (fixture.audio.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();
      expect(fixture.audio.error, isNull);
      expect(fixture.audio.dirty, isTrue);
      expect(
        fixture.audio.preview.value.cues[ProjectSoundCue.uiConfirm]!.source,
        ProjectSoundSource.custom,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('save-project-audio')),
      );
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('save-project-audio')));
        while (fixture.audio.saving) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();
      expect(fixture.audio.error, isNull);
      expect(fixture.audio.dirty, isFalse);
      await tester.runAsync(() async {
        final reopened = LocalMapWorkspaceAdapter();
        expect(
          (await reopened.loadFieldAbilities(fixture.session))
              .configuration!
              .disabledAbilityIds,
          {'dive', 'rock_climb', 'defog'},
        );
        expect(
          (await reopened.loadAudio(fixture.session))
              .configuration!
              .cues[ProjectSoundCue.uiConfirm]!
              .source,
          ProjectSoundSource.custom,
        );
      });
      expect(
        fixture.reader.paths.where((path) => path.startsWith('maps/')),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final storage in [
    ProjectSessionStorage.manifest,
    ProjectSessionStorage.workingCatalog,
  ]) {
    test(
      'audio import, library metadata and selected blob remain targeted for $storage',
      () async {
        final root = await Directory.systemTemp.createTemp('audio-library-');
        addTearDown(() => root.delete(recursive: true));
        const project = ProjectManifest(name: 'Son', maps: [], tilesets: []);
        if (storage == ProjectSessionStorage.workingCatalog) {
          final store = await CatalogStorageStore.open(projectRoot: root.path);
          await WorkingProjectCatalog.create(
            store: store,
            projectId: 'audio',
            project: project,
          );
        } else {
          await File('${root.path}/project.json')
              .writeAsString(jsonEncode(project.toJson()));
        }
        final source = File('${root.path}/selected.wav');
        await source.writeAsBytes(_audioWav());
        final session = ProjectSession(
          sessionId: root.path,
          name: 'Son',
          directoryPath: root.path,
          storage: storage,
        );
        final reader = _Reader();
        final adapter = LocalMapWorkspaceAdapter(reader: reader);
        if (storage == ProjectSessionStorage.manifest) {
          await adapter.loadProject(session);
        } else {
          await adapter.loadCatalog(session);
        }
        final initial = await adapter.loadAudio(session);
        reader.paths.clear();
        final imported = await adapter.importAudio(
          session,
          source.path,
          'Cloche',
          initial.revision,
        );
        final page = await adapter.queryAudio(session);
        expect(page.entries.single.label, 'Cloche');
        expect(page.entries.single.id, imported.entry.id);
        final selected = await adapter.resolveAudio(session, imported.entry.id);
        expect(await File(selected.path).readAsBytes(), _audioWav());
        expect(selected.mimeType, 'audio/wav');
        final saved = await adapter.saveAudioCue(
          session,
          ProjectSoundCue.uiConfirm,
          ProjectSoundBinding(
            source: ProjectSoundSource.custom,
            mediaId: imported.entry.id,
            gain: .5,
          ),
          imported.revision,
        );
        expect(
          saved.configuration!.cues[ProjectSoundCue.uiConfirm]!.mediaId,
          imported.entry.id,
        );
        expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
        final reopened = LocalMapWorkspaceAdapter();
        expect(
          (await reopened.loadAudio(session))
              .configuration!
              .cues[ProjectSoundCue.uiConfirm]!
              .gain,
          .5,
        );
      },
    );
  }

  test('CS and audio canonical settings writes preserve Surf and avoid unrelated maps', () async {
    final root = await Directory.systemTemp.createTemp('cs-audio-persist-');
    addTearDown(() => root.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
      store: store,
      projectId: 'cs-audio',
      project: const ProjectManifest(
        name: 'CS',
        maps: [],
        tilesets: [],
        settings: ProjectSettings(
          surf: ProjectSurfSettings(speedCellsPerSecond: 6),
        ),
      ),
    );
    final session = ProjectSession(
      sessionId: root.path,
      name: 'CS',
      directoryPath: root.path,
      storage: ProjectSessionStorage.workingCatalog,
    );
    final reader = _Reader();
    final adapter = LocalMapWorkspaceAdapter(reader: reader);
    await adapter.loadCatalog(session);
    var cs = await adapter.loadFieldAbilities(session);
    reader.paths.clear();
    cs = await adapter.saveFieldAbility(
      session,
      FieldAbility.dive,
      false,
      cs.revision,
    );
    expect(cs.configuration!.disabledAbilities, {FieldAbility.dive});
    var audio = await adapter.loadAudio(session);
    audio = await adapter.saveAudioCue(
      session,
      ProjectSoundCue.uiConfirm,
      const ProjectSoundBinding(source: ProjectSoundSource.builtin, gain: .3),
      audio.revision,
    );
    expect(audio.configuration!.cues[ProjectSoundCue.uiConfirm]!.gain, .3);
    audio = await adapter.saveAudioCue(
      session,
      ProjectSoundCue.uiConfirm,
      null,
      audio.revision,
    );
    expect(audio.configuration?.cues ?? {}, isEmpty);
    final reopened = LocalMapWorkspaceAdapter();
    expect(
      (await reopened.loadFieldAbilities(session))
          .configuration!
          .disabledAbilities,
      {FieldAbility.dive},
    );
    expect(
      (await reopened.loadSurf(session)).configuration!.speedCellsPerSecond,
      6,
    );
    expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
  });

  testWidgets(
    'the Surf widget persists through the canonical adapter and reopens without map reads',
    (tester) async {
      final fixture = (await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp(
          'surf-widget-persist-',
        );
        final store = await CatalogStorageStore.open(projectRoot: root.path);
        await WorkingProjectCatalog.create(
          store: store,
          projectId: 'surf-ui',
          project: const ProjectManifest(name: 'Surf', maps: [], tilesets: []),
        );
        final session = ProjectSession(
          sessionId: root.path,
          name: 'Surf',
          directoryPath: root.path,
          storage: ProjectSessionStorage.workingCatalog,
        );
        final reader = _Reader();
        final adapter = LocalMapWorkspaceAdapter(reader: reader);
        await adapter.loadCatalog(session);
        final owner = ProjectSurfController(
          session: session,
          port: adapter,
          dimension: ProjectDimension.threeD,
        );
        await owner.open();
        return (root: root, session: session, reader: reader, owner: owner);
      }))!;
      addTearDown(fixture.owner.dispose);
      addTearDown(() => fixture.root.delete(recursive: true));
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectSurfPanel(owner: fixture.owner),
            ),
          ),
        ),
      );
      final reads = fixture.reader.paths.length;
      await tester.tap(find.byKey(const ValueKey('surf-enabled')));
      await tester.pump();
      expect(fixture.owner.preview.value.enabled, isTrue);
      expect(fixture.reader.paths.length, reads);
      await tester.runAsync(() async {
        await tester.ensureVisible(
          find.byKey(const ValueKey('save-project-surf')),
        );
        await tester.tap(find.byKey(const ValueKey('save-project-surf')));
        while (fixture.owner.saving) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();
      expect(fixture.owner.error, isNull);
      expect(fixture.owner.dirty, isFalse);
      final reopened = await tester.runAsync(
        () => LocalMapWorkspaceAdapter().loadSurf(fixture.session),
      );
      expect(reopened!.configuration!.enabled, isTrue);
      expect(
        fixture.reader.paths.where((path) => path.startsWith('maps/')),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  test(
    'native metadata reader does not decode unrelated malformed sections',
    () async {
      final root = await Directory.systemTemp.createTemp('surf-reader-');
      addTearDown(() => root.delete(recursive: true));
      final project = const ProjectManifest(
        name: 'Scope',
        maps: [],
        tilesets: [],
      ).toJson();
      project['version'] = 'v9';
      project['settings'] = const ProjectSettings(
        dimension: ProjectDimension.threeD,
        tileWidth: 32,
        tileHeight: 48,
      ).toJson();
      project['characters'] = ['malformed unrelated character'];
      project['facts'] = ['malformed unrelated fact'];
      project['maps'] = ['malformed unrelated map'];
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(project));
      final session = ProjectSession(
        sessionId: root.path,
        name: 'Scope',
        directoryPath: root.path,
      );
      final selected = await LocalWorkshopReader(session).read(
        metadataFields: {'settings'},
        operation: (project, _, _) async => project,
      );
      expect(selected.characters, isEmpty);
      expect(selected.facts, isEmpty);
      expect(selected.maps, isEmpty);
      expect(selected.settings.surf, isNull);
      final badges = await LocalWorkshopReader(session).read(
        metadataFields: {'badges'},
        operation: (project, _, _) async => project,
      );
      expect(badges.settings.dimension, ProjectDimension.threeD);
      expect(badges.settings.tileWidth, 32);
      expect(badges.settings.tileHeight, 48);
    },
  );
  for (final unrelated in [0, 24]) {
    test(
      'working Surf saves reopen with $unrelated unrelated facts and no map reads',
      () async {
        final root = await Directory.systemTemp.createTemp('surf-persist-');
        addTearDown(() => root.delete(recursive: true));
        final store = await CatalogStorageStore.open(projectRoot: root.path);
        final project = ProjectManifest(
          name: 'Surf',
          maps: const [],
          tilesets: const [],
          facts: [
            for (var i = 0; i < unrelated; i++)
              NarrativeFactDefinition(id: 'fact-$i', label: 'Fait $i'),
          ],
        );
        await WorkingProjectCatalog.create(
          store: store,
          projectId: 'surf',
          project: project,
        );
        final session = ProjectSession(
          sessionId: root.path,
          name: 'Surf',
          directoryPath: root.path,
          storage: ProjectSessionStorage.workingCatalog,
        );
        final reader = _Reader();
        final adapter = LocalMapWorkspaceAdapter(reader: reader);
        await adapter.loadCatalog(session);
        var state = await adapter.loadSurf(session);
        expect(state.configuration, isNull);
        for (final enabled in [true, false]) {
          reader.paths.clear();
          reader.fields.clear();
          final configuration = ProjectSurfSettings(
            enabled: enabled,
            requiresKnownMove: false,
            accessMode: ProjectSurfAccessMode.always,
          );
          state = await adapter.saveSurf(
            session,
            configuration,
            state.revision,
          );
          expect(state.configuration, configuration);
          expect(
            reader.paths.where((path) => path.startsWith('maps/')),
            isEmpty,
          );
          expect(reader.fields.where((field) => field == 'facts'), isEmpty);
          expect(
            (await LocalMapWorkspaceAdapter().loadSurf(session)).configuration,
            configuration,
          );
        }
      },
    );
  }
}

class _Reader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final fields = <String>[];
  final _local = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<String> canonicalizeDirectory(String path) =>
      _local.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => _local.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    paths.add(relativePath);
    return _local.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) async* {
    paths.add(relativePath);
    final bytes = await _local.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    if (relativePath.startsWith('catalog/objects/')) {
      final object = jsonDecode(utf8.decode(bytes)) as Map;
      final payload = object['payload'];
      if (object['type'] == 'unit' &&
          payload is Map &&
          payload['section'] == r'$projectDefinition') {
        fields.add((payload['value'] as Map)['field'] as String);
      }
    }
    yield bytes;
  }
}

List<int> _audioWav() {
  final bytes = Uint8List(8044);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, utf8.encode('RIFF'));
  data.setUint32(4, bytes.length - 8, Endian.little);
  bytes.setRange(8, 16, utf8.encode('WAVEfmt '));
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 8000, Endian.little);
  data.setUint32(28, 8000, Endian.little);
  data.setUint16(32, 1, Endian.little);
  data.setUint16(34, 8, Endian.little);
  bytes.setRange(36, 40, utf8.encode('data'));
  data.setUint32(40, 8000, Endian.little);
  bytes.fillRange(44, bytes.length, 128);
  return bytes;
}
