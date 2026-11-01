import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/artifact_ref.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/artifact_store.dart';
import '../../ports/project_file_reader.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';

final class Gen5BattleSourceImportActions {
  const Gen5BattleSourceImportActions({required this.artifactStore});

  final ArtifactStore artifactStore;

  static final descriptor = AuthoringActionDescriptor(
    id: 'pokemon.gen5_battle_source.import',
    version: 1,
    summary: 'Import a verified Gen 5 battle source for one project species',
    inputSchemaId:
        'pokemap.authoring/pokemon.gen5_battle_source.import.input.v1',
    outputSchemaId:
        'pokemap.authoring/pokemon.gen5_battle_source.import.output.v1',
    riskLevel: AuthoringRiskLevel.medium,
    resourceKinds: const ['gen5BattleSourceFile', 'pokemonDocument'],
    capabilityIds: const ['authoring.gameData.pokemon'],
    requiredPermissions: const [
      AuthoringPermission.projectWrite,
      AuthoringPermission.importRun
    ],
    guarantees: const [
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.atomic,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
    ],
    extensions: const {
      'constraints': {
        'projectStorage': 'working-catalog-only',
        'conflictPolicy': 'preserve',
        'playerExecution': 'unverified',
      },
      'inputSchema': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['binding', 'bundleHandle', 'speciesPath'],
        'properties': {
          'binding': {
            'type': 'object',
            'additionalProperties': false,
            'required': [
              'kind',
              'schemaVersion',
              'projectSpeciesId',
              'species',
              'nationalDex',
              'release',
              'sourceRevision',
              'bundleSha256'
            ],
            'properties': {
              'kind': {'const': 'avelune.gen5-battle-source-binding'},
              'schemaVersion': {'const': 1},
              'projectSpeciesId': {'type': 'string'},
              'species': {'type': 'string'},
              'nationalDex': {'type': 'integer', 'minimum': 1, 'maximum': 649},
              'release': {'type': 'string'},
              'sourceRevision': {
                'type': 'string',
                'pattern': r'^[0-9a-f]{40}$'
              },
              'bundleSha256': {'type': 'string', 'pattern': r'^[0-9a-f]{64}$'},
            },
          },
          'bundleHandle': {'type': 'string'},
          'speciesPath': {'type': 'string'},
        },
      },
    },
  );

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    final args = context.request.parameters;
    if (args.length != 3 ||
        args['binding'] is! Map ||
        args['bundleHandle'] is! String ||
        args['speciesPath'] is! String ||
        !context.snapshot.materializedCatalogProject ||
        !context.snapshot.manifest.pokemon.enabled) {
      throw const FormatException('Invalid Gen 5 battle source import');
    }
    final raw = Map<String, dynamic>.from(args['binding'] as Map);
    final id = raw['projectSpeciesId'];
    final dex = raw['nationalDex'];
    if (id is! String || dex is! int) {
      throw const FormatException('Invalid Gen 5 project identity');
    }
    final candidate = Uint8List.fromList(utf8.encode(jsonEncode(raw)));
    final binding = Gen5BattleSourceBinding.decode(candidate,
        expectedSha256: sha256.convert(candidate).toString(),
        expectedProjectSpeciesId: id,
        expectedProjectNationalDex: dex);
    final speciesPath = args['speciesPath'] as String;
    final speciesDirectory = context.snapshot.manifest.pokemon.speciesDir;
    try {
      if (validateProjectRelativePath(speciesPath).join('/') != speciesPath ||
          validateProjectRelativePath(speciesDirectory).join('/') !=
              speciesDirectory ||
          !speciesPath.startsWith('$speciesDirectory/') ||
          !speciesPath.toLowerCase().endsWith('.json')) {
        throw const FormatException('Invalid project species path');
      }
    } on WorkspaceAccessException {
      throw const FormatException('Invalid project species path');
    }
    final identity = pokemonSpeciesResourceIdentity(id);
    final scope = context.snapshot.scopedStorageRevisions;
    final bytes = context.snapshot.findResourceBytes(identity);
    if (scope == null ||
        bytes == null ||
        context.snapshot.resourceStorageKeys[identity] != speciesPath ||
        scope[speciesPath] == null ||
        scope[speciesPath] != context.snapshot.resourceFingerprints[identity]) {
      throw const FormatException('Project species scope is unavailable');
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Project species is malformed');
    }
    final species = PokemonSpeciesFile.fromJson(decoded);
    if (species.id != id || species.nationalDex != dex) {
      throw const FormatException('Project species identity differs');
    }
    final handle = args['bundleHandle'] as String;
    final ref = artifactStore.inspect(handle);
    if (ref == null ||
        ref.mediaType != 'application/json' ||
        ref.byteLength < 1 ||
        ref.byteLength > gen5BattleSourceBundleMaxBytes) {
      throw const FormatException('Gen 5 source artifact is unavailable');
    }
    final bundle = Uint8List.fromList(await artifactStore.read(handle));
    if (ContentArtifactRef.fromBytes(bundle, mediaType: ref.mediaType) != ref) {
      throw const FormatException('Gen 5 source artifact changed');
    }
    binding.resolve(bundle,
        expectedProjectSpeciesId: species.id,
        expectedProjectNationalDex: species.nationalDex);
    final paths = <String, List<int>>{
      binding.bindingPath: binding.encode(),
      binding.bundlePath: bundle,
    };
    final changes = <AuthoringResourceChange>[];
    final diffs = <AuthoringDiffEntry>[];
    for (final entry in paths.entries) {
      if (!scope.containsKey(entry.key)) {
        throw const FormatException(
            'Gen 5 source storage scope is not prepared');
      }
      final identity = 'gen5BattleSource:${entry.key}';
      final before = context.snapshot.findResourceBytes(identity);
      if ((scope[entry.key] == null) != (before == null) ||
          (before != null &&
              (context.snapshot.resourceStorageKeys[identity] != entry.key ||
                  context.snapshot.resourceFingerprints[identity] !=
                      scope[entry.key]))) {
        throw const FormatException('Gen 5 source storage scope changed');
      }
      if (before != null) {
        if (!_sameBytes(before, entry.value)) {
          throw const FormatException('Existing Gen 5 source data differs');
        }
        continue;
      }
      final resource = AuthoringResourceRef(
          kind: 'gen5BattleSourceFile',
          id: sha256.convert(utf8.encode(entry.key)).toString());
      changes.add(AuthoringResourceChange(
          resource: resource,
          storageKey: entry.key,
          beforeBytes: null,
          afterBytes: entry.value));
      diffs.add(AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: resource,
          path: '/',
          after: {'byteLength': entry.value.length}));
    }
    return AuthoringMutationDraft(
      changeSet: changes.isEmpty
          ? AuthoringChangeSet.noChanges()
          : AuthoringChangeSet(changes: changes, diff: AuthoringDiff(diffs)),
      preview: {
        'operation': 'pokemon.gen5_battle_source.import',
        'projectSpeciesId': id,
        'nationalDex': dex,
        'idempotent': changes.isEmpty
      },
    );
  }
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
