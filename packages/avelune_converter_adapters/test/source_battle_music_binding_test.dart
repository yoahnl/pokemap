import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:avelune_converter_adapters/src/source_battle_music_binding.dart';
import 'support/native_writer_fixture.dart';
import 'support/native_trainer_fixture.dart';
import 'support/native_media_source_fixture.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';

const _defaults = {
  'WildBattleBGM': 'FRLG Battle (VS Wild Pokemon)',
  'TrainerBattleBGM': 'FRLG Battle (VS Trainer)',
  'WildVictoryBGM': 'FRLG Victory (VS Wild Pokemon)',
  'TrainerVictoryBGM': 'FRLG Victory (VS Trainer)',
};
const _renamed = {
  'WildBattleBGM':
      'FRLG Battle Music - Wild Pokemon (Battle (VS Wild Pokemon))',
  'TrainerBattleBGM': 'FRLG Battle Music - Trainer (Battle (VS Trainer))',
  'WildVictoryBGM':
      'FRLG Battle Victory - Wild Pokemon (Victory (VS Wild Pokemon))',
  'TrainerVictoryBGM': 'FRLG Battle Victory - Trainer (Victory (VS Trainer))',
};

Future<LiteralTileFixture> _fixture(
        {bool renamed = false,
        Map<String, List<int>> extra = const {},
        String? sourceRootPath}) =>
    LiteralTileFixture.create(
        namespace: 'battle-music-fixture',
        sourceRootPath: sourceRootPath,
        includeEventSystem: true,
        interpretationProfile: syntheticSourceInterpretationProfile,
        scriptsBytes: syntheticInterpretationArchive,
        extraFiles: {
          'PBS/items.txt':
              utf8.encode('[ORIGINAL]\nName = Original\nPocket = 1\n'),
          'PBS/metadata.txt': utf8.encode(
              '[0]\n${_defaults.entries.map((e) => '${e.key} = ${e.value}\n').join()}[1]\nWalkCharset = Player\n'),
          'Graphics/Characters/Player.png': image
              .encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
          'Data/metadata.dat': literalFixtureMarshal({
            0: LiteralFixtureObject('GameData::Metadata', {
              '@id': 0,
              '@wild_battle_BGM': _defaults['WildBattleBGM'],
              '@trainer_battle_BGM': _defaults['TrainerBattleBGM'],
              '@wild_victory_BGM': _defaults['WildVictoryBGM'],
              '@trainer_victory_BGM': _defaults['TrainerVictoryBGM'],
            })
          }),
          for (final name in (renamed ? _renamed : _defaults).values)
            'Audio/BGM/$name.wav': sourceMapMusicFixtureWav(),
          ...extra,
        });

Future<SourceCatalogProjection> _project(LiteralTileFixture f,
    {ScanCancellation? cancellation}) async {
  final pbs = await const SourcePbsParser()
      .read(snapshot: f.snapshot, files: f.files, cancellation: cancellation);
  return const SourceCatalogProjector().read(
      source: f.source,
      pbs: pbs,
      files: f.files,
      nativeMapIds: {1: 'native-map'},
      cancellation: cancellation);
}

void main() {
  test('catalogue imports attested battle and victory defaults automatically',
      () async {
    final f = await _fixture();
    final before = canonicalHashOf(f.source.toJson());
    final result = await _project(f);
    final audio = result.toJson()['battleAudio'];
    expect(audio, isA<Map>());
    expect(
        (audio as Map).keys,
        containsAll([
          'wildBattleMusicPath',
          'trainerBattleMusicPath',
          'wildVictoryMusicPath',
          'trainerVictoryMusicPath'
        ]));
    final imports = result.assetMutations
        .where((m) =>
            (m.parameters['usages'] as List?)?.contains('battleMusic') ?? false)
        .toList();
    expect(imports, hasLength(4));
    expect(audio.values,
        everyElement(isIn(imports.map((m) => m.parameters['logicalPath']))));
    expect(canonicalHashOf(f.source.toJson()), before);
  });

  test(
      'closed renamed battle audio adaptation retains exact declarations and files',
      () async {
    final f = await _fixture(renamed: true);
    final result = await _project(f);
    expect(result.toJson()['battleAudio'], isA<Map>());
    final evidence = result.evidence['battleMusic'] as Map;
    final bindings = evidence['bindings'] as List;
    expect(bindings, hasLength(4));
    expect(bindings.every((b) => b['resolution'] == 'closedRenamedSourceAudio'),
        isTrue);
    for (final b in bindings) {
      expect(_defaults.values, contains(b['declaredName']));
      expect(
          _renamed.values.any((name) =>
              b['sourceAudioFile']['relativePath'] == 'Audio/BGM/$name.wav'),
          isTrue);
      expect(b['sourceAudioFile']['sha256'], isNotEmpty);
    }
    expect(evidence['battleAuthority'], 'aveluneNative');
    expect(evidence['aiCalls'], 0);
  });
  test(
      'battle defaults survive canonical catalogue writer and strict reopening',
      () async {
    final f = await _fixture(renamed: true);
    final parent =
        await Directory.systemTemp.createTemp('battle-audio-writer-');
    try {
      const limits = sourceCatalogStudyWriteLimits;
      final literal = await const LiteralTileComposer().compose(
          source: f.source,
          files: f.files,
          selectedSourceMapIds: [1],
          projectName: 'Battle audio proof',
          parentPath: parent.path,
          folderName: 'native',
          limits: limits);
      final semantic = await const SourceSemanticStudyComposer().compose(
          source: f.source, base: literal, files: f.files, limits: limits);
      expect(semantic, isNotNull);
      final catalogs = await const SourceCatalogStudyComposer(
              automaticNativeEncounters: false)
          .compose(
              source: f.source,
              base: semantic!,
              files: f.files,
              limits: limits);
      expect(catalogs, isNotNull);
      final draft = catalogs!.draft;
      final action = draft.mutations
          .singleWhere((m) => m.actionId == 'project.battle_audio.update');
      expect(action.parameters, catalogs.projection.battleAudio!.toJson());
      expect(action.domain, OperationDomain.project);
      final approval = approveNativeFixtureDraft(draft);
      final receipt = await const NativeProjectWriter()
          .write(approval.plan, approval.context, draft, limits: limits);
      expect(receipt.verified, isTrue);
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [parent.path], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(receipt.projectPath);
      try {
        final snapshot = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        expect(snapshot.loadDiagnostics, isEmpty);
        expect(snapshot.manifest.battleAudio, catalogs.projection.battleAudio);
        for (final path in action.parameters.values.whereType<String>()) {
          expect(await File('${receipt.projectPath}/$path').readAsBytes(),
              sourceMapMusicFixtureWav());
        }
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
      final mutations = [
        for (final m in draft.mutations)
          if (m.actionId == 'project.battle_audio.update')
            NativeMutation(
                operationId: m.operationId,
                actionId: m.actionId,
                sourceEntityIds: m.sourceEntityIds,
                targetEntityIds: m.targetEntityIds,
                parameters: {
                  ...m.parameters,
                  'trainerBattleMusicPath': 'assets/audio/forged.wav'
                },
                limits: limits)
          else
            m
      ];
      final forged = copyNativeFixtureDraft(draft,
          folderName: 'forged', mutations: mutations, limits: limits);
      final forgedApproval = approveNativeFixtureDraft(forged);
      await expectLater(
          const NativeProjectWriter().write(
              forgedApproval.plan, forgedApproval.context, forged,
              limits: limits),
          throwsA(isA<NativeWriteException>()));
      expect(await Directory('${parent.path}/forged').exists(), isFalse);
    } finally {
      await parent.delete(recursive: true);
    }
  });

  test('qualified gym music overlays only native trainer audio fields',
      () async {
    final bundle = NativePsdkTrainerBundle.builtin();
    const type = 'FRLG_LEADER_Brock';
    final f = await _fixture(renamed: true, extra: {
      ...nativeMediaSourceFiles(bundle),
      ...nativeTrainerFixtureFiles([(type: type, name: 'Brock', version: 0)]),
      'PBS/trainer_types.txt': utf8.encode(
          '[$type]\nName = Leader\nBaseMoney = 30\nBattleBGM = FRLG Battle (VS Gym Leader)\nVictoryBGM = FRLG Victory (VS Gym Leader)\n'),
      'Data/trainer_types.dat': literalFixtureMarshal({
        const LiteralFixtureSymbol(type):
            const LiteralFixtureObject('GameData::TrainerType', {
          '@id': LiteralFixtureSymbol(type),
          '@base_money': 30,
          '@battle_BGM': 'FRLG Battle (VS Gym Leader)',
          '@victory_BGM': 'FRLG Victory (VS Gym Leader)'
        })
      }),
      'Audio/BGM/FRLG Battle Music - Gym Leader (Battle (VS Gym Leader)).wav':
          sourceMapMusicFixtureWav(),
      'Audio/BGM/FRLG Battle Victory - Gym Leader (Victory (VS Gym Leader)).wav':
          sourceMapMusicFixtureWav(),
    });
    final pbs = await const SourcePbsParser()
        .read(snapshot: f.snapshot, files: f.files);
    final key = pbs.entries
        .singleWhere((e) => e.family == SourcePbsFamily.trainers)
        .identity!;
    final qualification = await NativeTrainerCatalogQualification.prepare(
        normalizedSource: f.source,
        source: pbs,
        files: f.files,
        nativeCatalog: bundle,
        requestedTrainers: [key]);
    expect(qualification.refusals, isEmpty);
    final result = await const SourceCatalogProjector().read(
        source: f.source,
        pbs: pbs,
        files: f.files,
        nativeMapIds: {1: 'native-map'},
        requestedTrainerKeys: [key],
        nativeTrainerQualification: qualification,
        nativeTrainerBundle: bundle,
        nativeTrainerMovePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults);
    final trainer = result.trainers.single;
    expect(trainer.battleMusicPath, isNotNull);
    expect(trainer.victoryMusicPath, isNotNull);
    final original = (qualification.rows.single['nativeTrainer'] as Map)
        .cast<String, dynamic>();
    expect(
        trainer
            .copyWith(battleMusicPath: null, victoryMusicPath: null)
            .toJson(),
        original);
    final rows = (result.evidence['battleMusic'] as Map)['bindings'] as List;
    expect(rows.where((row) => row['owner'] == type), hasLength(2));
  });

  test('qualified champion music overlays only native trainer audio fields',
      () async {
    final bundle = NativePsdkTrainerBundle.builtin();
    const type = 'FRLG_CHAMPION';
    final f = await _fixture(renamed: true, extra: {
      ...nativeMediaSourceFiles(bundle),
      ...nativeTrainerFixtureFiles([(type: type, name: 'Blue', version: 0)]),
      'PBS/trainer_types.txt': utf8.encode(
          '[$type]\nName = Leader\nBaseMoney = 30\nBattleBGM = FRLG The Last Battle (VS Rival)\nVictoryBGM = FRLG Victory (VS Gym Leader)\n'),
      'Data/trainer_types.dat': literalFixtureMarshal({
        const LiteralFixtureSymbol(type):
            const LiteralFixtureObject('GameData::TrainerType', {
          '@id': LiteralFixtureSymbol(type),
          '@base_money': 30,
          '@battle_BGM': 'FRLG The Last Battle (VS Rival)',
          '@victory_BGM': 'FRLG Victory (VS Gym Leader)'
        })
      }),
      'Audio/BGM/FRLG Battle Intro - Champion (The Last Battle (VS Rival)).wav':
          sourceMapMusicFixtureWav(),
      'Audio/BGM/FRLG Battle Victory - Gym Leader (Victory (VS Gym Leader)).wav':
          sourceMapMusicFixtureWav(),
    });
    final pbs = await const SourcePbsParser()
        .read(snapshot: f.snapshot, files: f.files);
    final key = pbs.entries
        .singleWhere((e) => e.family == SourcePbsFamily.trainers)
        .identity!;
    final qualification = await NativeTrainerCatalogQualification.prepare(
        normalizedSource: f.source,
        source: pbs,
        files: f.files,
        nativeCatalog: bundle,
        requestedTrainers: [key]);
    expect(qualification.refusals, isEmpty);
    final result = await const SourceCatalogProjector().read(
        source: f.source,
        pbs: pbs,
        files: f.files,
        nativeMapIds: {1: 'native-map'},
        requestedTrainerKeys: [key],
        nativeTrainerQualification: qualification,
        nativeTrainerBundle: bundle,
        nativeTrainerMovePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults);
    final trainer = result.trainers.single;
    expect(trainer.battleMusicPath, isNotNull);
    expect(trainer.victoryMusicPath, isNotNull);
    final original = (qualification.rows.single['nativeTrainer'] as Map)
        .cast<String, dynamic>();
    expect(
        trainer
            .copyWith(battleMusicPath: null, victoryMusicPath: null)
            .toJson(),
        original);
    final rows = (result.evidence['battleMusic'] as Map)['bindings'] as List;
    expect(rows.where((row) => row['owner'] == type), hasLength(2));
  });

  test(
      'battle audio refuses ambiguity missing names compiled mismatch and invalid media',
      () async {
    for (final variant in <({Map<String, List<int>> files, String reason})>[
      (
        files: {
          'Audio/BGM/${_defaults['TrainerBattleBGM']}.mp3':
              sourceMapMusicFixtureWav()
        },
        reason: 'audio_missing_or_ambiguous'
      ),
      (
        files: {
          'PBS/metadata.txt': utf8.encode('[0]\nTrainerBattleBGM = Unknown\n'),
          'Data/metadata.dat': literalFixtureMarshal({
            0: const LiteralFixtureObject('GameData::Metadata',
                {'@id': 0, '@trainer_battle_BGM': 'Unknown'})
          })
        },
        reason: 'audio_missing_or_ambiguous'
      ),
      (
        files: {
          'Data/metadata.dat': literalFixtureMarshal({
            0: const LiteralFixtureObject('GameData::Metadata',
                {'@id': 0, '@trainer_battle_BGM': 'Different'})
          })
        },
        reason: 'compiled_mismatch'
      ),
      (
        files: {
          'PBS/metadata.txt': utf8.encode(
              '[0]\nTrainerBattleBGM = Name\nTrainerBattleBGM = Again\n')
        },
        reason: 'metadata_duplicate'
      ),
      (
        files: {'PBS/metadata.txt': utf8.encode('[0]\nStartMoney = 3000\n')},
        reason: 'compiled_mismatch'
      ),
    ]) {
      final f = await _fixture(extra: variant.files);
      await expectLater(
          _project(f),
          throwsA(isA<ContractError>().having(
              (e) => e.code, 'code', 'source.battle_music.${variant.reason}')));
    }
    final corrupt = await _fixture(extra: {
      'Audio/BGM/${_defaults['TrainerBattleBGM']}.wav':
          utf8.encode('invalid audio')
    });
    await expectLater(
        _project(corrupt),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.artifact.audio')));
  });

  test(
      'battle audio checks source changes cancellation quotas and source profile',
      () async {
    final f = await _fixture();
    final pbs = await const SourcePbsParser()
        .read(snapshot: f.snapshot, files: f.files);
    Future<SourceBattleMusicBinding> read(
            {NativeWriteLimits limits = const NativeWriteLimits(),
            ScanCancellation? cancellation,
            NormalizedSourceProject? source}) =>
        SourceBattleMusicBinding.read(
            source: source ?? f.source,
            pbs: pbs,
            files: f.files,
            trainers: const [],
            limits: limits,
            cancellation: cancellation);
    final before = f.files.reads.length;
    await expectLater(
        read(cancellation: ScanCancellation()..cancel()),
        throwsA(isA<ContractError>()
            .having((e) => e.code, 'code', 'source.cancelled')));
    expect(f.files.reads.length, before);
    for (final limits in [
      const NativeWriteLimits(maxArtifactBytes: 128),
      const NativeWriteLimits(maxTotalArtifactBytes: 128),
      const NativeWriteLimits(maxMutations: 1)
    ]) {
      await expectLater(
          read(limits: limits),
          throwsA(isA<ContractError>()
              .having((e) => e.code, 'code', 'source.battle_music.quota')));
    }
    for (final path in [
      'PBS/metadata.txt',
      'Data/metadata.dat',
      'Audio/BGM/${_defaults['TrainerBattleBGM']}.wav'
    ]) {
      f.files.overrides[path] = [...f.sourceBytes[path]!, 0];
      await expectLater(
          read(),
          throwsA(isA<ContractError>().having(
              (e) => e.code, 'code', 'source.battle_music.source_changed')));
      f.files.overrides.clear();
    }
    final foreign = await const RmxpSourceNormalizer()
        .normalize(snapshot: f.snapshot, files: f.files);
    await expectLater(
        read(source: foreign),
        throwsA(isA<ContractError>()
            .having((e) => e.code, 'code', 'source.battle_music.profile')));
    final binding = await read();
    expect(() => binding.evidence['bindings'] = [], throwsUnsupportedError);
    expect(() => (binding.evidence['bindings'] as List).clear(),
        throwsUnsupportedError);
  });
  test(
      'public workflow exposes battle defaults before approval and publishes their plan',
      () async {
    final parent =
        await Directory.systemTemp.createTemp('battle-audio-public-');
    final workflow = ConverterWorkflow();
    try {
      await _fixture(renamed: true, sourceRootPath: '${parent.path}/source');
      final output = await Directory('${parent.path}/output').create();
      final outputPath = await output.resolveSymbolicLinks();
      final selection = ConverterSourceSelection(
          rootPath: '${parent.path}/source',
          logicalProjectNamespace: ConverterId('battle-music-fixture'));
      final snapshot = await workflow.scanSource(selection);
      workflow.updateSettings(ConverterStudySettings(
          projectName: 'Battle music workflow',
          parentPath: outputPath,
          folderName: 'native-public',
          selectedSourceMapIds: [1],
          interpretationProfile: syntheticSourceInterpretationProfile,
          profileAcknowledgement: SourceStudyAcknowledgement(
              sourceSnapshotHash: snapshot.canonicalHash,
              profileEvidenceHash: snapshot.profile.evidenceHash,
              humanConfirmed: true,
              reason: 'Controlled synthetic battle music fixture')));
      final prepared = await workflow.prepareStudy();
      expect(prepared.canApprove, isTrue);
      final capability = prepared.targetCapabilities.capabilities.singleWhere(
          (c) =>
              c.capabilityId.value ==
              'native.study.project.battle_audio.update');
      expect(capability.status, CapabilityStatus.supported);
      expect(
          capability.evidence.any((e) => e
              .toJson()
              .toString()
              .contains('source_battle_music_binding_test.dart')),
          isTrue);
      final plan = prepared.previewPlan!.toJson();
      final findings = (plan['findings'] as List).cast<Map>();
      final musical = findings
          .where((f) => f.toString().contains('workflow.catalogs.battle_music'))
          .toList();
      expect(musical, hasLength(4));
      expect(
          musical.every((f) =>
              f.toString().contains('closedRenamedSourceAudio') &&
              f.toString().contains('SHA-256')),
          isTrue);
      final approval = workflow.approvePrepared(
          sessionRevision: prepared.sessionRevision,
          preparationHash: prepared.preparationHash,
          humanConfirmed: true);
      final result = await workflow.writeApproved(approval);
      expect(result.published, isTrue);
      expect(result.receipt.verified, isTrue);
    } finally {
      await workflow.dispose();
      await parent.delete(recursive: true);
    }
  }, skip: !Platform.isMacOS);
}
