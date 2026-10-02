import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_fixture.dart';
import '../assets/resource_source_fixture.dart';

Future<ResourceInformationFixture> lifecycleFixture() async {
  final base = smartInformationFixture();
  final preset = base.smartTileCatalog.presets.single;
  final draft = ProjectSmartTileAuthoringDraft.fromJson({
    ...preset.toJson()..remove('status'),
    'id': 'editing',
    'targetPresetId': preset.id,
    'sourcePresetId': preset.id,
    'lastStage': 'connections',
    'sourceTilesetIds': ['sheet'],
    'atlases':
        base.smartTileCatalog.atlases.map((item) => item.toJson()).toList(),
    'primaryAtlasId': 'atlas',
    'materials':
        base.smartTileCatalog.materials.map((item) => item.toJson()).toList(),
  });
  final project = base.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
          categories: base.smartTileCatalog.categories,
          atlases: base.smartTileCatalog.atlases,
          materials: base.smartTileCatalog.materials,
          presets: [preset],
          drafts: [draft]));
  final fixture = await ResourceInformationFixture.create(project);
  final bytes = sourcePng(width: 64, height: 64);
  final artifact = ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
  final catalog = AssetCatalog(records: [
    AssetRecord(
        id: 'image', logicalPath: 'assets/source.png', artifact: artifact)
  ]);
  for (final entry in <String, List<int>>{
    assetCatalogStorageKey: utf8.encode(jsonEncode(catalog.toJson())),
    assetBlobStorageKey(artifact): bytes,
    'assets/source.png': bytes,
  }.entries) {
    final file = File('${fixture.root.path}/${entry.key}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value);
  }
  return fixture;
}

Future<ProjectManifest> independentRead(
    ResourceInformationFixture fixture) async {
  const reader = LocalProjectFileReader();
  final handles = WorkspaceHandleStore();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [fixture.root.path], fileReader: reader);
  final opened = await ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles)
      .openProject(fixture.root.path);
  try {
    return (await ProjectSnapshotLoader(handles: handles)
            .load(opened.projectHandle))
        .manifest;
  } finally {
    handles.closeWorkspace(opened.workspaceHandle);
  }
}

void main() {
  test('terrain lifecycle preserves raw nested data outside its owner',
      () async {
    final fixture = await lifecycleFixture();
    addTearDown(fixture.dispose);
    final file = File('${fixture.root.path}/project.json');
    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final sheet = (raw['tilesets'] as List).single as Map<String, dynamic>;
    sheet['extensionData'] = {
      'authored': {
        'labels': ['été', 'préservé'],
        'revision': 12
      }
    };
    raw['unrelatedMetadata'] = {
      'nested': [false, 'stable']
    };
    await file.writeAsString(jsonEncode(raw));
    final originalSheets = jsonEncode(raw['tilesets']);
    final originalMetadata = jsonEncode(raw['unrelatedMetadata']);
    final image =
        await File('${fixture.root.path}/assets/source.png').readAsBytes();
    Future<void> unchanged() async {
      final current = jsonDecode(await file.readAsString()) as Map;
      expect(jsonEncode(current['tilesets']), originalSheets);
      expect(jsonEncode(current['unrelatedMetadata']), originalMetadata);
      expect(await File('${fixture.root.path}/assets/source.png').readAsBytes(),
          image);
    }

    await fixture.mutate('smart_tile.preset.rename',
        {'presetId': 'ground', 'name': 'Chemin préservé'});
    await unchanged();
    await fixture.mutate('smart_tile.preset.duplicate', {
      'presetId': 'ground',
      'newDraftId': 'copy-draft',
      'targetPresetId': 'copy',
      'name': 'Copie'
    });
    await unchanged();
    await fixture
        .mutate('smart_tile.preset.publish', {'draftId': 'copy-draft'});
    await unchanged();
    for (final (action, parameters) in [
      ('smart_tile.preset.draft.delete', {'draftId': 'editing'}),
      ('smart_tile.preset.delete', {'presetId': 'ground'})
    ]) {
      final plan = await fixture.plan(action, parameters);
      final confirmation = await fixture.command('confirm',
          {'projectHandle': fixture.project, 'planId': plan.data['planId']});
      final applied = await fixture.command('apply', {
        'projectHandle': fixture.project,
        'planId': plan.data['planId'],
        'operationId': action,
        'confirmationToken': confirmation.data['confirmationToken']
      });
      expect(applied.status, AuthoringResultStatus.success,
          reason: applied.toJson().toString());
      await unchanged();
    }
    expect((await independentRead(fixture)).smartTileCatalog.presets.single.id,
        'copy');
  });

  test('JSONL rename persists metadata then publication keeps the new title',
      () async {
    final fixture = await lifecycleFixture();
    addTearDown(fixture.dispose);
    final described = await fixture.command('describe', {});
    expect(described.status, AuthoringResultStatus.success);
    for (final id in [
      'smart_tile.preset.rename',
      'smart_tile.preset.duplicate'
    ]) {
      final descriptor = (described.data['mutationActions'] as List)
          .cast<Map>()
          .firstWhere((item) => item['id'] == id);
      expect(
          ((descriptor['extensions'] as Map)['inputSchema']
              as Map)['additionalProperties'],
          isFalse);
    }
    final original = await fixture.read();
    final saved = original.smartTileCatalog.drafts.single;
    final rule = saved.rules.single;
    final candidate = rule.candidates.single;
    final edited = saved.copyWith(rules: [
      rule.copyWith(
          candidates: [candidate.copyWith(label: 'Fleurs', weight: 7)])
    ]);
    await fixture
        .mutate('smart_tile.preset.draft.upsert', {'draft': edited.toJson()});
    final image =
        await File('${fixture.root.path}/assets/source.png').readAsBytes();
    final preview = await fixture.plan('smart_tile.preset.rename',
        {'presetId': 'ground', 'name': 'Chemin de l’été'});
    expect(preview.status, AuthoringResultStatus.success);
    expect((await fixture.read()).smartTileCatalog.presets.single.name, 'Sol');
    await fixture.apply(preview);
    final renamed = await independentRead(fixture);
    expect(
        renamed.smartTileCatalog.presets.single,
        original.smartTileCatalog.presets.single
            .copyWith(name: 'Chemin de l’été'));
    expect(renamed.smartTileCatalog.drafts.single,
        edited.copyWith(name: 'Chemin de l’été'));
    await fixture.mutate('smart_tile.preset.publish', {'draftId': saved.id});
    final published = await independentRead(fixture);
    expect(published.smartTileCatalog.presets.single.name, 'Chemin de l’été');
    expect(
        published.smartTileCatalog.presets.single.rules.single.candidates.single
            .label,
        'Fleurs');
    expect(
        published.smartTileCatalog.presets.single.rules.single.candidates.single
            .weight,
        7);
    expect(published.smartTileCatalog.drafts, isEmpty);
    expect(await File('${fixture.root.path}/assets/source.png').readAsBytes(),
        image);
    expect(published.elements, original.elements);
  });

  test(
      'JSONL published copy isolates resources and applies no implicit publication',
      () async {
    final fixture = await lifecycleFixture();
    addTearDown(fixture.dispose);
    final original = await fixture.read();
    final planning = Stopwatch()..start();
    final preview = await fixture.plan('smart_tile.preset.duplicate', {
      'presetId': 'ground',
      'newDraftId': 'copy-draft',
      'targetPresetId': 'copy',
      'name': 'Copie'
    });
    planning.stop();
    expect(preview.status, AuthoringResultStatus.success,
        reason: preview.toJson().toString());
    expect((await fixture.read()).smartTileCatalog.drafts,
        original.smartTileCatalog.drafts);
    final applying = Stopwatch()..start();
    await fixture.apply(preview);
    applying.stop();
    stdout.writeln('UWU5_TERRAIN_COPY_PLAN_US=${planning.elapsedMicroseconds} '
        'APPLY_US=${applying.elapsedMicroseconds} '
        'MAPS=${original.maps.length} TILESETS=${original.tilesets.length}');
    final independent = await independentRead(fixture);
    final copy = independent.smartTileCatalog.drafts
        .firstWhere((item) => item.id == 'copy-draft');
    expect(independent.smartTileCatalog.presets,
        original.smartTileCatalog.presets);
    expect(copy.primaryAtlasId, isNot('atlas'));
    final edited = copy
        .copyWith(atlases: [copy.atlases.single.copyWith(name: 'Atlas copie')]);
    await fixture
        .mutate('smart_tile.preset.draft.upsert', {'draft': edited.toJson()});
    await fixture.mutate('smart_tile.preset.publish', {'draftId': copy.id});
    final published = await independentRead(fixture);
    expect(
        published.smartTileCatalog.presets
            .firstWhere((item) => item.id == 'ground'),
        original.smartTileCatalog.presets.single);
    expect(
        published.smartTileCatalog.atlases
            .firstWhere((item) => item.id == 'atlas'),
        original.smartTileCatalog.atlases.single);
    expect(
        published.smartTileCatalog.presets
            .firstWhere((item) => item.id == 'copy')
            .name,
        'Copie');
    expect(published.smartTileCatalog.drafts.single,
        original.smartTileCatalog.drafts.single);
    final conflict = await fixture.plan('smart_tile.preset.duplicate', {
      'presetId': 'ground',
      'newDraftId': 'another',
      'targetPresetId': 'copy',
      'name': 'Collision'
    });
    expect(conflict.status, AuthoringResultStatus.failure);
    expect(conflict.error!.details['domainCode'],
        'smart_tile.duplicate.identity_conflict');
  });

  test(
      'rename no-op writes nothing and deletion cannot orphan the retained draft',
      () async {
    final fixture = await lifecycleFixture();
    addTearDown(fixture.dispose);
    final bytes = await File('${fixture.root.path}/project.json').readAsBytes();
    final unchanged = await fixture.plan(
        'smart_tile.preset.rename', {'presetId': 'ground', 'name': '  Sol  '});
    expect(unchanged.status, AuthoringResultStatus.success);
    final unchangedApply = await fixture.apply(unchanged);
    expect(unchangedApply.status, AuthoringResultStatus.failure);
    expect(unchangedApply.error!.details['domainCode'], 'plan.no_changes');
    expect(
        await File('${fixture.root.path}/project.json').readAsBytes(), bytes);
    final refused =
        await fixture.plan('smart_tile.preset.delete', {'presetId': 'ground'});
    expect(refused.status, AuthoringResultStatus.failure);
    expect(refused.error!.details['domainCode'],
        'smart_tile.preset.references_blocking');
    final plan = await fixture
        .plan('smart_tile.preset.draft.delete', {'draftId': 'editing'});
    expect(plan.status, AuthoringResultStatus.success);
    final confirmation = await fixture.command('confirm',
        {'projectHandle': fixture.project, 'planId': plan.data['planId']});
    final applied = await fixture.command('apply', {
      'projectHandle': fixture.project,
      'planId': plan.data['planId'],
      'operationId': 'delete-draft',
      'confirmationToken': confirmation.data['confirmationToken']
    });
    expect(applied.status, AuthoringResultStatus.success);
    final independent = await independentRead(fixture);
    expect(independent.smartTileCatalog.presets.single.id, 'ground');
    expect(independent.smartTileCatalog.drafts, isEmpty);
    expect(
        await File('${fixture.root.path}/assets/source.png').exists(), isTrue);
  });
}
