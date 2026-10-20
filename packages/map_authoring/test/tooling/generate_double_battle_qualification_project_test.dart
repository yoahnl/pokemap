import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../tool/generate_double_battle_qualification_project.dart'
    as generator;

void main() {
  late Directory temporary;
  late Directory source;
  late File profile;
  late File receipt;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('double-battle-qa-');
    source = Directory(p.join(temporary.path, 'source'));
    profile = File(p.join(temporary.path, 'profile.json'));
    receipt = File(p.join(temporary.path, 'fixture.json'));
  });
  tearDown(() => temporary.delete(recursive: true));

  Future<Map<String, Object?>> generate() =>
      generator.generateDoubleBattleQualificationProject(
          projectRoot: source, profileFile: profile, receiptFile: receipt);

  test('creates a native Standard New Game with four identifiable members',
      () async {
    final report = await generate();
    expect(report['kind'], 'doubleBattleQualification');
    final project = await _project(source);
    expect(project.pokemon.enabled, isTrue);
    expect(project.pokemon.ruleset, PokemonRulesetProfile.standardV1);
    final exportProfile =
        GamePackageExportProfile.decodeUtf8(await profile.readAsBytes());
    expect(exportProfile.gameId, 'games.avelune.double-battle-qualification');
    expect(exportProfile.gameVersion, '0.2.0');
    final map = MapData.fromJson(jsonDecode(
        await File(p.join(source.path, project.maps.single.relativePath))
            .readAsString()));
    final state = createNewGameStateFromProject(
        project: project, startMap: map, tileWidthPx: 32, tileHeightPx: 32);
    final party = state.party.members;
    expect(party, hasLength(4));
    expect(party.map((member) => member.individualId).toSet(), hasLength(4));
    expect(party.every((member) => member.individualId.isNotEmpty), isTrue);
    expect(party.map((member) => member.nickname).toSet(), hasLength(4));
    expect(party.map((member) => member.currentHp).toSet(), hasLength(4));
    expect(party.map((member) => member.currentPpByMoveId).toList(),
        project.newGame.initialParty.map((member) => member.currentPpByMoveId));
    expect(
        project.newGame.initialBag
            .singleWhere((entry) => entry.itemId == 'qa_potion')
            .quantity,
        1);
    expect(project.trainers, hasLength(2));
    for (final trainer in project.trainers) {
      expect(trainer.battleFormat, BattleFormat.doubles);
      expect(trainer.team, hasLength(4));
    }
    expect(project.trainers.last.team.first.level,
        greaterThan(project.trainers.first.team.first.level));
    expect(report['creationActionId'], 'project.create_prepared_native');
    expect(
        await File(p.join(source.path, 'runtime_host_launch_save.json'))
            .exists(),
        isFalse);
  });

  test('authors real battle outcomes and an explicit separate healer',
      () async {
    await generate();
    final project = await _project(source);
    expect(project.facts.map((fact) => fact.id),
        containsAll(['qa.victory', 'qa.defeat']));
    final battles = project.scenes
        .expand((scene) => scene.graph.nodes)
        .where((node) => node.kind == SceneNodeKind.battle)
        .toList();
    expect(battles, hasLength(2));
    for (final scene in project.scenes.where((scene) =>
        scene.graph.nodes.any((node) => node.kind == SceneNodeKind.battle))) {
      final battle = scene.graph.nodes
          .singleWhere((node) => node.kind == SceneNodeKind.battle);
      final payload = battle.payload as SceneBattlePayload;
      expect(payload.battleKind, 'trainer');
      expect(payload.defeatRecovery, SceneBattleDefeatRecovery.continueScene);
      expect(payload.declaredOutcomes, containsAll(['victory', 'defeat']));
      expect(
          scene.graph.edges
              .where((edge) => edge.fromNodeId == battle.id)
              .map((edge) => edge.kind),
          containsAll(
              [SceneEdgeKind.battleVictory, SceneEdgeKind.battleDefeat]));
      expect(jsonEncode(scene.toJson()), isNot(contains('healParty')));
    }
    expect(
        jsonEncode(project.scenes
            .singleWhere((scene) => scene.id == 'qa-heal')
            .toJson()),
        contains('healParty'));
    expect(project.eventRegistry!.mode, EventSystemMode.v2Only);
    expect(project.eventRegistry!.records, hasLength(4));
    final instructions =
        await File(p.join(source.path, project.dialogues.single.relativePath))
            .readAsString();
    expect(instructions, contains('one member recovers to 1 HP'));
    expect(instructions, contains('others remain fainted'));
    expect(instructions, contains('no full heal or teleport'));
    expect(instructions, isNot(contains('party stays fainted')));
  });

  test('exports a certified package with Pokemon data and generated media',
      () async {
    final report = await generate();
    expect(report['totalBytes'] as int, lessThan(10 * 1024 * 1024));
    final artifact = await const CanonicalGamePackageExportService()
        .exportToFile(
            projectRoot: source,
            profile: GamePackageExportProfile.decodeUtf8(
                await profile.readAsBytes()),
            outputFile: File(p.join(temporary.path, 'doubles.avelunegame')));
    expect(artifact.certification.isCertified, isTrue);
    expect(artifact.inspection.receipt.pokemonRuleset.profileId,
        'pokemap-standard-v1');
    final archive =
        ZipDecoder().decodeBytes(artifact.packageBytes, verify: true);
    final descriptor = Map<String, Object?>.from(jsonDecode(
        utf8.decode(archive.findFile('project/project.json')!.content)) as Map);
    final published = PortableCatalogPublication.decodeProjectSync(descriptor,
        readObject: (reference) => archive
            .findFile(
                'project/${PortableCatalogPublication.objectPath(reference)}')!
            .content);
    expect(published.newGame.initialParty, hasLength(4));
    expect(
        published.trainers.every((trainer) =>
            trainer.battleFormat == BattleFormat.doubles &&
            trainer.team.length == 4),
        isTrue);
    final assets = AssetCatalog.fromJson(jsonDecode(
        await File(p.join(source.path, assetCatalogStorageKey))
            .readAsString()));
    expect(assets.records, isNotEmpty);
    for (final asset in assets.records) {
      final bytes =
          await File(p.join(source.path, asset.logicalPath)).readAsBytes();
      expect(image.decodePng(bytes), isNotNull);
      expect(ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png'),
          asset.artifact);
      expect(archive.findFile('project/${asset.logicalPath}'), isNotNull);
    }
  });

  test('has deterministic canonical content across output roots', () async {
    final first = await generate();
    final second = await generator.generateDoubleBattleQualificationProject(
        projectRoot: Directory(p.join(temporary.path, 'other')),
        profileFile: File(p.join(temporary.path, 'other-profile.json')),
        receiptFile: File(p.join(temporary.path, 'other-receipt.json')));
    expect(second['sourceIdentitySha256'], first['sourceIdentitySha256']);
    expect(second['files'], first['files']);
  });

  test('refuses existing destinations without replacing contents', () async {
    await source.create();
    final marker = File(p.join(source.path, 'keep.txt'));
    await marker.writeAsString('keep');
    await expectLater(generate(), throwsA(isA<FileSystemException>()));
    expect(await marker.readAsString(), 'keep');
    expect(await profile.exists(), isFalse);
    expect(await receipt.exists(), isFalse);
  });

  test('refuses an existing profile before creating the source', () async {
    await profile.writeAsString('keep');
    await expectLater(generate(), throwsA(isA<FileSystemException>()));
    expect(await profile.readAsString(), 'keep');
    expect(await source.exists(), isFalse);
    expect(await receipt.exists(), isFalse);
  });

  test('requires separate external profile and receipt destinations', () async {
    for (final output in [
      (File(p.join(source.path, 'profile.json')), receipt),
      (profile, profile),
      (File(source.path), receipt),
      (profile, File(p.join(source.path, 'receipt.json'))),
    ]) {
      await expectLater(
          generator.generateDoubleBattleQualificationProject(
              projectRoot: source,
              profileFile: output.$1,
              receiptFile: output.$2),
          throwsArgumentError);
      expect(await source.exists(), isFalse);
      expect(await profile.exists(), isFalse);
      expect(await receipt.exists(), isFalse);
    }
  });
}

Future<ProjectManifest> _project(Directory root) async =>
    ProjectManifest.fromJson(jsonDecode(
        await File(p.join(root.path, 'project.json')).readAsString()));
