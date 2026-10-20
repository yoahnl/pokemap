import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../../../tool/generate_synthetic_catalog_project.dart' as generator;

void main() {
  test('canonical Standard export retains its explicit format and inspects',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('standard-package-');
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
        'pokemap-standard-v1');
    final inspected =
        GamePackageInspector().inspect(await output.readAsBytes());
    expect(inspected.receipt.packageSha256, artifact.packageSha256);
    expect(
        inspected.receipt.pokemonRuleset,
        const PokemonRulesetReference(
            profileId: 'pokemap-standard-v1', schemaVersion: 1));
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
    expect(published.pokemon.ruleset.toJson(), shared['standardProfile']);
    expect(published.trainers.single.toJson()['battleFormat'], 'doubles');
    expect(published.trainers.single.team, hasLength(2));
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
        <String, Object?>{'profile': shared['standardProfile']}
      ),
      (
        'campaign.trainer.upsert',
        <String, Object?>{'value': shared['doubles']}
      ),
    ];
    for (var index = 0; index < operations.length; index++) {
      final operation = operations[index];
      final id = 'standard-package-$index';
      final planned = await mutations.plan(
        opened.projectHandle,
        AuthoringRequest(
          requestId: id,
          actionId: operation.$1,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision:
              (await snapshots.load(opened.projectHandle)).revision,
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
