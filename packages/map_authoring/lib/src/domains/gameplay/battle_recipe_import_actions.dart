import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';

final class BattleRecipeImportActions {
  const BattleRecipeImportActions({required this.artifactStore});
  final ArtifactStore artifactStore;

  static final descriptor = AuthoringActionDescriptor(
    id: 'pokemon.move_recipe.import',
    version: 1,
    summary:
        'Import a verified battle recipe and its resources for a local move',
    inputSchemaId: 'pokemap.authoring/pokemon.move_recipe.import.input.v1',
    outputSchemaId: 'pokemap.authoring/pokemon.move_recipe.import.output.v1',
    riskLevel: AuthoringRiskLevel.medium,
    resourceKinds: const ['battleRecipeFile', 'pokemonCatalog'],
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
      AuthoringGuarantee.undoable
    ],
    extensions: const {
      'constraints': {
        'projectStorage': 'working-catalog-only',
        'conflictPolicy': 'preserve-unless-explicit-binding-replacement',
        'soundResources': 'validated-structure',
        'soundCodecs': [
          'wav-pcm',
          'wav-ieee-float',
          'ogg-vorbis',
          'ogg-opus',
          'mpeg-layer-3'
        ],
        'maxSoundBytes': BattleRecipeBundleInspector.maxSoundBytes,
        'playerExecution': 'unverified',
      },
      'inputSchema': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['projectBinding', 'recipeHandle', 'resources'],
        'properties': {
          'projectBinding': {
            'type': 'object',
            'additionalProperties': false,
            'required': [
              'kind',
              'schemaVersion',
              'unsupportedBehavior',
              'binding'
            ],
            'properties': {
              'kind': {'const': 'avelune.battle-recipe-binding'},
              'schemaVersion': {'const': 1},
              'unsupportedBehavior': {'const': 'legacy'},
              'catalogMoveId': {'type': 'string'},
              'recipeMediaId': {'type': 'string'},
              'binding': {
                'type': 'object',
                'additionalProperties': false,
                'required': [
                  'schemaVersion',
                  'projectMoveId',
                  'sourceMoveId',
                  'catalogReleaseId',
                  'recipeId',
                  'variant',
                  'revision',
                  'recipeSha256'
                ],
                'properties': {
                  'schemaVersion': {'const': 1},
                  'projectMoveId': {'type': 'string'},
                  'sourceMoveId': {'type': 'string'},
                  'catalogReleaseId': {'type': 'string'},
                  'recipeId': {'type': 'string'},
                  'variant': {'type': 'string'},
                  'revision': {'type': 'string'},
                  'recipeSha256': {
                    'type': 'string',
                    'pattern': r'^[0-9a-f]{64}$'
                  },
                },
              },
            },
          },
          'recipeHandle': {'type': 'string'},
          'replaceExisting': {'type': 'boolean'},
          'resources': {
            'type': 'array',
            'maxItems': 256,
            'items': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['id', 'sha256', 'mediaType', 'artifactHandle'],
              'properties': {
                'id': {'type': 'string'},
                'sha256': {'type': 'string', 'pattern': r'^[0-9a-f]{64}$'},
                'mediaType': {
                  'enum': [
                    'image/png',
                    'application/vnd.avelune.particle+json',
                    'audio/wav',
                    'audio/ogg',
                    'audio/mpeg'
                  ]
                },
                'artifactHandle': {'type': 'string'},
              },
            },
          },
        },
      },
    },
  );

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    final args = context.request.parameters;
    if (args.keys.any((key) => !{
          'projectBinding', 'recipeHandle', 'resources', 'replaceExisting',
        }.contains(key)) ||
        args['projectBinding'] is! Map ||
        args['recipeHandle'] is! String ||
        args['resources'] is! List ||
        (args.containsKey('replaceExisting') && args['replaceExisting'] is! bool)) {
      throw const FormatException('Invalid battle recipe import');
    }
    final projectBinding = BattleRecipeProjectBinding.fromJson(
      Map<String, dynamic>.from(args['projectBinding'] as Map),
    );
    final binding = projectBinding.binding;
    final catalogBytes =
        context.snapshot.findResourceBytes('pokemonCatalog:moves');
    if (catalogBytes == null) {
      throw const FormatException('Missing move catalog');
    }
    final catalog = jsonDecode(utf8.decode(catalogBytes));
    if (catalog is! Map ||
        catalog['catalog'] != 'moves' ||
        catalog['entries'] is! List ||
        (catalog['entries'] as List)
                .whereType<Map>()
                .where((entry) => entry['id'] == binding.projectMoveId)
                .length !=
            1) {
      throw const FormatException('Local move is unavailable');
    }
    final handle = args['recipeHandle'] as String;
    final recipeRef = artifactStore.inspect(handle);
    if (recipeRef == null || recipeRef.byteLength > 1048576) {
      throw const FormatException('Recipe artifact is unavailable');
    }
    final recipeBytes = Uint8List.fromList(await artifactStore.read(handle));
    final entries = args['resources'] as List;
    if (entries.length > 256) throw const FormatException('Too many resources');
    final media = <String, Uint8List>{};
    final declared = <String, (String, String)>{};
    var total = recipeBytes.length;
    for (final raw in entries) {
      if (raw is! Map ||
          raw.length != 4 ||
          raw['id'] is! String ||
          raw['sha256'] is! String ||
          raw['mediaType'] is! String ||
          raw['artifactHandle'] is! String) {
        throw const FormatException('Invalid resource artifact');
      }
      final id = raw['id'] as String;
      final hash = raw['sha256'] as String;
      final type = raw['mediaType'] as String;
      final resourceHandle = raw['artifactHandle'] as String;
      battleRecipeBlobPath(hash, type, projectMoveId: binding.projectMoveId);
      final ref = artifactStore.inspect(resourceHandle);
      if (ref == null || media.containsKey(id)) {
        throw const FormatException('Resource artifact is unavailable');
      }
      if (type.startsWith('audio/') &&
          ref.byteLength > BattleRecipeBundleInspector.maxSoundBytes) {
        throw const FormatException('Sound exceeds byte limit');
      }
      total += ref.byteLength;
      if (total > 64 * 1024 * 1024) {
        throw const FormatException('Bundle too large');
      }
      media[id] = Uint8List.fromList(await artifactStore.read(resourceHandle));
      declared[id] = (hash, type);
    }
    final bundle = const BattleRecipeBundleInspector().inspect(
      binding,
      recipeBytes,
      media,
      limits: const BattleRecipeBundleLimits(
          maxTextures: 256,
          maxTextureBytes: 8 * 1024 * 1024,
          maxBundleBytes: 64 * 1024 * 1024,
          maxDimension: 2048,
          maxTexturePixels: 4000000,
          maxTotalPixels: 16000000),
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
      expectedProjectMoveId: binding.projectMoveId,
      expectedCatalogReleaseId: binding.catalogReleaseId,
    );
    for (final resource in bundle.recipe.resources) {
      if (declared[resource.id] != (resource.sha256Hex, resource.mediaType)) {
        throw const FormatException('Resource identity differs from recipe');
      }
    }
    final paths = <String, List<int>>{
      battleRecipeBindingPath(binding.projectMoveId):
          utf8.encode(jsonEncode(projectBinding.toJson())),
      battleRecipeBlobPath(
          binding.recipeSha256, 'application/vnd.avelune.battle-recipe+json',
          projectMoveId: binding.projectMoveId): bundle.recipeBytes,
      for (final resource in bundle.recipe.resources)
        battleRecipeBlobPath(resource.sha256Hex, resource.mediaType,
            projectMoveId: binding.projectMoveId): bundle.media[resource.id]!,
    };
    final scope = context.snapshot.scopedStorageRevisions;
    final changes = <AuthoringResourceChange>[];
    final diffs = <AuthoringDiffEntry>[];
    for (final entry in paths.entries) {
      if (scope == null || !scope.containsKey(entry.key)) {
        throw const FormatException(
            'Battle recipe storage scope is not prepared');
      }
      final before =
          context.snapshot.findResourceBytes('battleRecipe:${entry.key}');
      if ((scope[entry.key] == null) != (before == null)) {
        throw const FormatException('Battle recipe storage scope changed');
      }
      if (before != null) {
        if (_sameBytes(before, entry.value)) continue;
        if (entry.key != battleRecipeBindingPath(binding.projectMoveId) ||
            args['replaceExisting'] != true) {
          throw const FormatException('Existing battle recipe data differs');
        }
      }
      final resource = AuthoringResourceRef(
        kind: 'battleRecipeFile',
        id: sha256.convert(utf8.encode(entry.key)).toString(),
      );
      changes.add(AuthoringResourceChange(
          resource: resource,
          storageKey: entry.key,
          beforeBytes: before,
          afterBytes: entry.value));
      diffs.add(before == null
          ? AuthoringDiffEntry(
              operation: AuthoringDiffOperation.add,
              resource: resource,
              path: '/',
              after: {'byteLength': entry.value.length})
          : AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource: resource,
              path: '/',
              before: {'byteLength': before.length},
              after: {'byteLength': entry.value.length}));
    }
    return AuthoringMutationDraft(
      changeSet: changes.isEmpty
          ? AuthoringChangeSet.noChanges()
          : AuthoringChangeSet(changes: changes, diff: AuthoringDiff(diffs)),
      preview: {
        'operation': 'pokemon.move_recipe.import',
        'projectMoveId': binding.projectMoveId,
        'idempotent': changes.isEmpty
      },
    );
  }
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
