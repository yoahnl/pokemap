import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../../../tool/generate_synthetic_catalog_project.dart' as generator;

void main() {
  test('contextual export derives its capability and preserves authored generic policy',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('contextual-package-');
    addTearDown(() => temporary.delete(recursive: true));
    final root = Directory('${temporary.path}/source');
    final profile = File('${temporary.path}/profile.json');
    await generator.generateSyntheticCatalogProject(
      projectRoot: root,
      profileFile: profile,
      receiptFile: File('${temporary.path}/source-receipt.json'),
    );
    final shared = jsonDecode(
      File('test/fixtures/trainer_battle_format.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final itemsFile = File('${root.path}/data/pokemon/catalogs/items.json');
    await itemsFile.parent.create(recursive: true);
    await itemsFile.writeAsString(jsonEncode(const ProjectItemCatalog(schemaVersion: 1, entries: []).toJson()));
    await _author(root, shared);
    final manifestFile = File('${root.path}/project.json');
    final before = await manifestFile.readAsBytes();
    final output = File('${temporary.path}/standard.avelunegame');
    final artifact =
        await const CanonicalGamePackageExportService().exportToFile(
      projectRoot: root,
      profile: GamePackageExportProfile.decodeUtf8(await profile.readAsBytes()),
      outputFile: output,
    );

    expect(await output.exists(), isTrue);
    expect(artifact.certification.isCertified, isTrue);
    expect(artifact.inspection.receipt.pokemonRuleset.profileId,
        'pokemap-contextual-v1');
    final inspected =
        GamePackageInspector().inspect(await output.readAsBytes());
    expect(inspected.receipt.packageSha256, artifact.packageSha256);
    expect(
        inspected.receipt.pokemonRuleset,
        const PokemonRulesetReference(
            profileId: 'pokemap-contextual-v1', schemaVersion: 1));
    final archive =
        ZipDecoder().decodeBytes(await output.readAsBytes(), verify: true);
    final descriptor = Map<String, Object?>.from(
      jsonDecode(utf8.decode(archive.findFile('project/project.json')!.content))
          as Map,
    );
    final published = PortableCatalogPublication.decodeProjectSync(
      descriptor,
      readObject: (reference) => archive
          .findFile(
            'project/${PortableCatalogPublication.objectPath(reference)}',
          )!
          .content,
    );
    expect(published.pokemon.ruleset, PokemonRulesetProfile.contextualV1);
    expect(artifact.manifest.compatibility.requiredCapabilities,
        contains(PokemonRulesetProfile.contextualCaptureCapabilityId));
    final itemPath = 'project/${published.pokemon.catalogFiles['items']}';
    final items = decodeProjectItemCatalog(jsonDecode(utf8.decode(archive.findFile(itemPath)!.content)));
    expect(items.entries.singleWhere((item) => item.id == 'eighth-synthetic-orb').capture!.contextualPolicy!.successEffects.single,
        isA<ProjectCaptureSetFriendship>().having((effect) => effect.value, 'value', 123));
    expect(await manifestFile.readAsBytes(), before);
  });
}

Future<void> _author(Directory root, Map<String, dynamic> shared) async {
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [root.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final opened = await ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
  ).openProject(root.path);
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final mutations = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: snapshots,
  );
  await mutations.attachProject(
    projectRootPath: root.path,
    workspaceHandle: opened.workspaceHandle,
    projectHandle: opened.projectHandle,
  );
  try {
    final operations = [
      (
        'pokemon.ruleset.set',
        <String, Object?>{'profile': PokemonRulesetProfile.contextualV1.toJson()}
      ),
      (
        'item.create',
        <String, Object?>{'definition': const ProjectItemDefinition(id: 'eighth-synthetic-orb', displayName: 'Eighth', pocketId: 'balls').toJson()}
      ),
      ('item.set_capture_effect', <String, Object?>{'itemId': 'eighth-synthetic-orb', 'capture': {
        'rateNumerator': 3, 'rateDenominator': 2, 'allowedEncounterKinds': ['walk'],
        'contextualPolicy': ProjectContextualCapturePolicy(rateRules: [ProjectCaptureRateRule(
          when: ProjectCaptureMatchCondition(field: ProjectCaptureMatchField.targetSpecies, values: {'eighth-synthetic-species'}),
          adjustment: ProjectCaptureRateAdd(17))], successEffects: [ProjectCaptureSetFriendship(123)]).toJson(),
      }}),
    ];
    for (var index = 0; index < operations.length; index++) {
      final operation = operations[index];
      final id = 'contextual-package-$index';
      final planned = await mutations.plan(
        opened.projectHandle,
        AuthoringRequest(
          requestId: id,
          actionId: operation.$1,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision:
              (await mutations.readWorkshopSnapshot(opened.projectHandle, actionId: operation.$1, parameters: operation.$2)).revision,
          idempotencyKey: id,
          parameters: operation.$2,
        ),
      );
      await mutations.apply(
        opened.projectHandle,
        planId: planned['planId'] as String,
        operationId: id,
      );
    }
  } finally {
    await mutations.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  }
}
