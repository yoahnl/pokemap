import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:image/image.dart' as image;

import '../api/authoring_read_api.dart';
import '../contracts/artifact_ref.dart';
import '../contracts/authoring_diff.dart';
import '../contracts/authoring_receipt.dart';
import '../domains/assets/asset_store.dart';
import '../ports/exclusive_project_directory.dart';
import '../ports/project_file_reader.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/journaled_transaction.dart';
import '../transactions/file_idempotency_store.dart';
import '../transactions/revision_set.dart';
import 'local_project_creation_service.dart';
import 'project_creation_contracts.dart';
import 'project_creation_kit.dart';
import 'project_creation_transaction.dart';
import 'project_open_service.dart';
import 'project_snapshot_loader.dart';
import 'workspace_handle_store.dart';
import 'workspace_policy.dart';

part '../security/native_project_creation_capability.dart';

const nativeProjectCreationMaxBytes = 500 * 1024 * 1024;
const nativeProjectCreationHardMaxBytes = 1280 * 1024 * 1024;
const nativeProjectCreationMaxResources = 32768;
const nativeProjectCreationActionId = 'project.create_prepared_native';

final class NativeProjectCreationArtifact {
  NativeProjectCreationArtifact(
      {required this.reference, required List<int> bytes})
      : bytes = Uint8List.fromList(bytes).asUnmodifiableView() {
    if (ContentArtifactRef.fromBytes(this.bytes,
            mediaType: reference.mediaType) !=
        reference) {
      throw const FormatException(
          'The native creation artifact differs from its content reference.');
    }
  }
  final ContentArtifactRef reference;
  final List<int> bytes;
  factory NativeProjectCreationArtifact.fromJson(Map<String, dynamic> json,
      {List<int> Function(Map<String, dynamic>)? artifactBytes}) {
    _keys(json, {'reference', 'base64'});
    return NativeProjectCreationArtifact(
        reference: ContentArtifactRef.fromJson(_object(json['reference'])),
        bytes: artifactBytes?.call(json) ??
            base64Decode(json['base64'] as String));
  }
  Map<String, Object?> toJson() =>
      {'reference': reference.toJson(), 'base64': base64Encode(bytes)};
}

final class NativeProjectCreationBorderFrame {
  const NativeProjectCreationBorderFrame(
      {required this.snapshotId,
      required this.frameIndex,
      required this.artifact});
  final String snapshotId;
  final int frameIndex;
  final NativeProjectCreationArtifact artifact;
  factory NativeProjectCreationBorderFrame.fromJson(Map<String, dynamic> json,
      {List<int> Function(Map<String, dynamic>)? artifactBytes}) {
    _keys(json, {'snapshotId', 'frameIndex', 'artifact'});
    return NativeProjectCreationBorderFrame(
        snapshotId: json['snapshotId'] as String,
        frameIndex: json['frameIndex'] as int,
        artifact: NativeProjectCreationArtifact.fromJson(
            _object(json['artifact']),
            artifactBytes: artifactBytes));
  }
  Map<String, Object?> toJson() => {
        'snapshotId': snapshotId,
        'frameIndex': frameIndex,
        'artifact': artifact.toJson()
      };
}

final class NativeProjectCreationInput {
  NativeProjectCreationInput(
      {required this.manifest,
      required Iterable<MapData> maps,
      required this.assetCatalog,
      Iterable<NativeProjectCreationArtifact> artifacts = const [],
      Map<String, String> dialogueSources = const {},
      this.itemCatalog,
      Iterable<PokemonCatalogFile> pokemonCatalogs = const [],
      Iterable<PokemonSpeciesFile> species = const [],
      Iterable<PokemonLearnsetFile> learnsets = const [],
      Iterable<PokemonEvolutionFile> evolutions = const [],
      Iterable<PokemonMediaFile> media = const [],
      Iterable<NativeProjectCreationBorderFrame> borderFrames = const []})
      : maps = List.unmodifiable(maps),
        artifacts = List.unmodifiable(artifacts),
        dialogueSources = Map.unmodifiable(dialogueSources),
        pokemonCatalogs = List.unmodifiable(pokemonCatalogs),
        species = List.unmodifiable(species),
        learnsets = List.unmodifiable(learnsets),
        evolutions = List.unmodifiable(evolutions),
        media = List.unmodifiable(media),
        borderFrames = List.unmodifiable(borderFrames);
  final ProjectManifest manifest;
  final List<MapData> maps;
  final AssetCatalog assetCatalog;
  final List<NativeProjectCreationArtifact> artifacts;
  final Map<String, String> dialogueSources;
  final ProjectItemCatalog? itemCatalog;
  final List<PokemonCatalogFile> pokemonCatalogs;
  final List<PokemonSpeciesFile> species;
  final List<PokemonLearnsetFile> learnsets;
  final List<PokemonEvolutionFile> evolutions;
  final List<PokemonMediaFile> media;
  final List<NativeProjectCreationBorderFrame> borderFrames;

  factory NativeProjectCreationInput.fromJson(Map<String, dynamic> json,
      {List<int> Function(Map<String, dynamic>)? artifactBytes}) {
    _keys(json, {
      'manifest',
      'maps',
      'assetCatalog',
      'artifacts',
      'dialogueSources',
      'itemCatalog',
      'pokemonCatalogs',
      'species',
      'learnsets',
      'evolutions',
      'media',
      'borderFrames'
    });
    List<T> list<T>(String key, T Function(Map<String, dynamic>) decode) => [
          for (final value in (json[key] as List? ?? const []))
            decode(_object(value))
        ];
    return NativeProjectCreationInput(
        manifest: ProjectManifest.fromJson(_object(json['manifest'])),
        maps: list('maps', MapData.fromJson),
        assetCatalog: AssetCatalog.fromJson(_object(json['assetCatalog'])),
        artifacts: list(
            'artifacts',
            (value) => NativeProjectCreationArtifact.fromJson(value,
                artifactBytes: artifactBytes)),
        dialogueSources: Map<String, String>.from(
            json['dialogueSources'] as Map? ?? const {}),
        itemCatalog: json['itemCatalog'] == null
            ? null
            : ProjectItemCatalog.fromJson(_object(json['itemCatalog'])),
        pokemonCatalogs: list('pokemonCatalogs', PokemonCatalogFile.fromJson),
        species: list('species', PokemonSpeciesFile.fromJson),
        learnsets: list('learnsets', PokemonLearnsetFile.fromJson),
        evolutions: list('evolutions', PokemonEvolutionFile.fromJson),
        media: list('media', PokemonMediaFile.fromJson),
        borderFrames: list(
            'borderFrames',
            (value) => NativeProjectCreationBorderFrame.fromJson(value,
                artifactBytes: artifactBytes)));
  }
  Map<String, Object?> toJson() => {
        'manifest': manifest.toJson(),
        'maps': [for (final value in maps) value.toJson()],
        'assetCatalog': assetCatalog.toJson(),
        'artifacts': [for (final value in artifacts) value.toJson()],
        'dialogueSources': dialogueSources,
        if (itemCatalog != null) 'itemCatalog': itemCatalog!.toJson(),
        'pokemonCatalogs': [
          for (final value in pokemonCatalogs) value.toJson()
        ],
        'species': [for (final value in species) value.toJson()],
        'learnsets': [for (final value in learnsets) value.toJson()],
        'evolutions': [for (final value in evolutions) value.toJson()],
        'media': [for (final value in media) value.toJson()],
        'borderFrames': [for (final value in borderFrames) value.toJson()]
      };
}

final class NativePreparedProjectCreation {
  NativePreparedProjectCreation._(
      this._kit, this.inventoryFingerprint, this.byteLength, this._inventory);
  final ProjectCreationKit _kit;
  final String inventoryFingerprint;
  final int byteLength;
  final List<_NativeCreationInventoryEntry> _inventory;
  int get resourceCount => _inventory.length;
  ProjectManifest get manifest => ProjectManifest.fromJson(
      _object(jsonDecode(utf8.decode(_kit.files['project.json']!))));

  void _requirePlan(AuthoringPlan plan) {
    final changes = plan.changeSet.changes;
    if (changes.length != _inventory.length) {
      throw const FormatException(
          'The native creation plan inventory changed.');
    }
    final byPath = {for (final value in _inventory) value.storageKey: value};
    for (final change in changes) {
      final expected = byPath.remove(change.storageKey);
      if (expected == null ||
          change.beforePayload != null ||
          change.afterPayload == null ||
          change.afterPayload!.byteLength != expected.byteLength ||
          change.afterPayload!.resourceRevision != expected.afterRevision) {
        throw const FormatException(
            'The native creation plan payload changed.');
      }
    }
    if (byPath.isNotEmpty) {
      throw const FormatException('The native creation plan is incomplete.');
    }
  }
}

final class NativeProjectCreationPlan {
  NativeProjectCreationPlan._(this.prepared, this.parentPath, this.folderName,
      this.projectPath, this.operationId, this.createdAt, this.expiresAt);
  final NativePreparedProjectCreation prepared;
  final String parentPath;
  final String folderName;
  final String projectPath;
  final String operationId;
  final DateTime createdAt;
  final DateTime expiresAt;
  String get projectId => 'project-$operationId';
  String get planId => 'plan-$operationId';
  String get beforeRevision => AuthoringRevisionSet([
        for (final item in prepared._inventory)
          AuthoringResourceRevision(
              resource: projectCreationResourceRef(item.storageKey, projectId),
              revision: null)
      ]).fingerprint;
  String get afterRevision => AuthoringRevisionSet([
        for (final item in prepared._inventory)
          AuthoringResourceRevision(
              resource: projectCreationResourceRef(item.storageKey, projectId),
              revision: item.afterRevision)
      ]).fingerprint;
  AuthoringDiff get diff => AuthoringDiff([
        for (final item in prepared._inventory)
          AuthoringDiffEntry(
              operation: AuthoringDiffOperation.add,
              resource: projectCreationResourceRef(item.storageKey, projectId),
              path: r'$',
              after: {'byteLength': item.byteLength})
      ]);
  String get inventoryFingerprint => prepared.inventoryFingerprint;
}

final class NativeProjectCreationReceipt {
  const NativeProjectCreationReceipt(
      {required this.projectPath,
      required this.manifest,
      required this.transactionReceipt,
      required this.inventoryFingerprint});
  final String projectPath;
  final ProjectManifest manifest;
  final AuthoringReceipt transactionReceipt;
  final String inventoryFingerprint;
  Map<String, Object?> toJson() => {
        'projectPath': projectPath,
        'manifest': manifest.toJson(),
        'transactionReceipt': transactionReceipt.toJson(),
        'inventoryFingerprint': inventoryFingerprint
      };
}

final class NativeProjectCreationService {
  const NativeProjectCreationService(
      {this.faultInjector, this.checkpoint, this.clock,
      this.maxInventoryBytes = nativeProjectCreationMaxBytes});
  final int maxInventoryBytes;
  final AuthoringTransactionFaultInjector? faultInjector;
  final DateTime Function()? clock;
  DateTime get _now => (clock?.call() ?? DateTime.now()).toUtc();
  final Future<void> Function(ProjectCreationCheckpoint, String)? checkpoint;

  Future<NativePreparedProjectCreation> prepare(
      NativeProjectCreationInput input) async {
    if (maxInventoryBytes < 1 ||
        maxInventoryBytes > nativeProjectCreationHardMaxBytes) {
      throw FormatException('native.creation.quota.invalid_limit: '
          'attempted=$maxInventoryBytes, minimum=1, '
          'limit=$nativeProjectCreationHardMaxBytes');
    }
    final files = <String, List<int>>{};
    final folded = <String>{};
    var size = 0;
    void add(String path, List<int> bytes, {bool shared = false}) {
      final segments = validateProjectRelativePath(path);
      if (segments.join('/') != path ||
          segments.any((part) =>
              part.startsWith('.') &&
              part != '.pokemap-assets.json' &&
              part != '.pokemap-store') ||
          path.contains('\\') ||
          path.contains(':')) {
        throw const FormatException('Unsafe native creation path.');
      }
      final previous = files[path];
      if (previous != null && shared && _sameBytes(previous, bytes)) return;
      if (!folded.add(path.toLowerCase())) {
        throw const FormatException('Duplicate native creation path.');
      }
      final attemptedResources = files.length + 1;
      if (attemptedResources > nativeProjectCreationMaxResources) {
        throw FormatException('native.creation.quota.resources: '
            'attempted=$attemptedResources, '
            'limit=$nativeProjectCreationMaxResources, path=$path');
      }
      final attemptedBytes = size + bytes.length;
      if (attemptedBytes > maxInventoryBytes) {
        throw FormatException('native.creation.quota.bytes: '
            'attempted=$attemptedBytes, limit=$maxInventoryBytes, path=$path');
      }
      size = attemptedBytes;
      files[path] = bytes is Uint8List
          ? bytes.asUnmodifiableView()
          : Uint8List.fromList(bytes).asUnmodifiableView();
    }

    void json(String path, Object value) =>
        add(path, utf8.encode(jsonEncode(value)));
    final manifest = ProjectManifest.fromJson(
        _object(jsonDecode(jsonEncode(input.manifest.toJson()))));
    json('project.json', manifest.toJson());
    final maps = {for (final map in input.maps) map.id: map};
    if (maps.length != input.maps.length ||
        maps.length != manifest.maps.length) {
      throw const FormatException(
          'Native map inventory differs from the manifest.');
    }
    for (final entry in manifest.maps) {
      final map = maps.remove(entry.id);
      if (map == null) throw const FormatException('A native map is missing.');
      if (!entry.relativePath.startsWith('maps/') ||
          !entry.relativePath.endsWith('.json')) {
        throw const FormatException(
            'Native map paths must be JSON resources under maps.');
      }
      json(entry.relativePath, map.toJson());
    }
    json(assetCatalogStorageKey, input.assetCatalog.toJson());
    final artifacts = <String, NativeProjectCreationArtifact>{};
    for (final artifact in input.artifacts) {
      if (artifacts.containsKey(artifact.reference.handle)) {
        throw const FormatException('Duplicate native creation artifact.');
      }
      artifacts[artifact.reference.handle] = artifact;
    }
    final usedArtifacts = <String>{};
    for (final record in input.assetCatalog.records) {
      final artifact = artifacts[record.artifact.handle];
      if (artifact == null || artifact.reference != record.artifact) {
        throw const FormatException(
            'A native asset lacks exact artifact bytes.');
      }
      usedArtifacts.add(record.artifact.handle);
      if (record.logicalPath.split('/').any((part) => part.startsWith('.'))) {
        throw const FormatException(
            'Native logical assets cannot use administrative paths.');
      }
      if (!record.logicalPath.startsWith('assets/') &&
          !record.logicalPath.startsWith('audio/')) {
        throw const FormatException(
            'Native asset paths must be under assets or audio.');
      }
      add(record.logicalPath, artifact.bytes);
      add(assetBlobStorageKey(artifact.reference), artifact.bytes,
          shared: true);
    }
    if (usedArtifacts.length != artifacts.length) {
      throw const FormatException('Unreferenced native creation artifact.');
    }
    final dialogues = Map<String, String>.from(input.dialogueSources);
    for (final entry in manifest.dialogues) {
      final source = dialogues.remove(entry.id);
      if (source == null) {
        throw const FormatException('A native dialogue source is missing.');
      }
      if (!entry.relativePath.startsWith('dialogues/') ||
          !entry.relativePath.endsWith('.yarn')) {
        throw const FormatException(
            'Native dialogue sources require dialogues/*.yarn paths.');
      }
      add(entry.relativePath, utf8.encode(source));
    }
    if (dialogues.isNotEmpty) {
      throw const FormatException('Unreferenced native dialogue source.');
    }
    if (input.itemCatalog != null) {
      json(
          manifest.pokemon.catalogFiles['items'] ??
              (throw const FormatException(
                  'An item catalog requires its configured native path.')),
          input.itemCatalog!.toJson());
    }
    final pokemon = manifest.pokemon;
    for (final path in [
      pokemon.dataRoot,
      pokemon.speciesDir,
      pokemon.learnsetsDir,
      pokemon.evolutionsDir,
      pokemon.mediaDir,
      ...pokemon.catalogFiles.values
    ]) {
      if (!path.startsWith('data/')) {
        throw const FormatException(
            'Native Pokemon data must remain under data.');
      }
    }
    for (final model in input.pokemonCatalogs) {
      final path = pokemon.catalogFiles[model.catalog];
      if (path == null) {
        throw const FormatException('Unknown native Pokemon catalog.');
      }
      json(path, model.toJson());
    }
    for (final model in input.species) {
      json('${pokemon.speciesDir}/${_id(model.id)}.json', model.toJson());
    }
    for (final model in input.learnsets) {
      json('${pokemon.learnsetsDir}/${_id(model.speciesId)}.json',
          model.toJson());
    }
    for (final model in input.evolutions) {
      json('${pokemon.evolutionsDir}/${_id(model.speciesId)}.json',
          model.toJson());
    }
    for (final model in input.media) {
      json('${pokemon.mediaDir}/${_id(model.speciesId)}.json', model.toJson());
    }
    final frames = <String, NativeProjectCreationBorderFrame>{};
    for (final frame in input.borderFrames) {
      if (frame.frameIndex < 0 ||
          frames.containsKey('${frame.snapshotId}\u0000${frame.frameIndex}')) {
        throw const FormatException('Duplicate or invalid border frame.');
      }
      frames['${frame.snapshotId}\u0000${frame.frameIndex}'] = frame;
    }
    for (final snapshot in manifest.borderCatalog.visualSnapshots) {
      final contentFrames = <BorderSnapshotContentFrame>[];
      for (final (index, frame) in snapshot.frames.indexed) {
        final inputFrame = frames.remove('${snapshot.id}\u0000$index');
        if (inputFrame == null ||
            inputFrame.artifact.reference.mediaType != 'image/png') {
          throw const FormatException(
              'A native border snapshot frame is missing.');
        }
        contentFrames.add(_borderFrame(frame, inputFrame.artifact.bytes));
        add(frame.relativeAssetPath, inputFrame.artifact.bytes, shared: true);
      }
      if (computeBorderSnapshotContentFingerprint(frames: contentFrames) !=
          snapshot.contentFingerprint) {
        throw const FormatException(
            'Native border snapshot content fingerprint differs from its frames.');
      }
    }
    if (frames.isNotEmpty) {
      throw const FormatException('Unreferenced native border frame.');
    }
    final kit = ProjectCreationKit(manifest, Map.unmodifiable(files));
    await _validateKit(kit);
    final inventory = [
      for (final path in (files.keys.toList()..sort()))
        _NativeCreationInventoryEntry(
            storageKey: path,
            afterRevision: computeAuthoringBytesFingerprint(files[path]!,
                logicalName: path),
            byteLength: files[path]!.length)
    ];
    return NativePreparedProjectCreation._(kit,
        _inventoryFingerprint(inventory), size, List.unmodifiable(inventory));
  }

  Future<NativeProjectCreationPlan> plan(
      {required NativePreparedProjectCreation prepared,
      required String parentPath,
      required String folderName,
      bool Function()? isCancelled}) async {
    _active(isCancelled);
    final target = await const LocalProjectCreationService()
        .validateDestination(_request(prepared, parentPath, folderName));
    _active(isCancelled);
    return NativeProjectCreationPlan._(
        prepared,
        parentPath,
        folderName,
        target,
        'native-creation-${_now.microsecondsSinceEpoch}-${_nonce++}',
        _now,
        _now.add(const Duration(minutes: 10)));
  }

  Future<NativeProjectCreationReceipt> publish(NativeProjectCreationPlan plan,
      {bool Function()? isCancelled}) async {
    _active(isCancelled);
    final replay = await _replay(plan);
    if (replay != null) return replay;
    if (!_now.isBefore(plan.expiresAt)) {
      throw const ProjectCreationException(
          'project.plan_expired', 'The prepared native creation plan expired.');
    }
    final request = _request(plan.prepared, plan.parentPath, plan.folderName);
    final service = const LocalProjectCreationService();
    if (await service.validateDestination(request) != plan.projectPath) {
      throw const ProjectCreationException('project.destination_changed',
          'The prepared native destination changed.');
    }
    await checkpoint?.call(
        ProjectCreationCheckpoint.beforeReservation, plan.projectPath);
    _active(isCancelled);
    if (await service.validateDestination(request) != plan.projectPath) {
      throw const ProjectCreationException(
          'project.destination_changed', 'The prepared native parent changed.');
    }
    _active(isCancelled);
    createExclusiveProjectDirectory(plan.projectPath);
    try {
      await checkpoint?.call(
          ProjectCreationCheckpoint.afterReservation, plan.projectPath);
      _active(isCancelled);
      final receipt = await writeProjectCreationKit(
          plan.projectPath, plan.prepared._kit,
          faultInjector: faultInjector,
          nativeCreation: plan.prepared,
          operationId: plan.operationId, verifyPublished: () async {
        await checkpoint?.call(
            ProjectCreationCheckpoint.afterApply, plan.projectPath);
        await _verifyInventory(plan);
        final reader = LocalProjectFileReader();
        for (final item in plan.prepared._inventory) {
          final bytes = await reader.readBytes(
              projectRoot: plan.projectPath, relativePath: item.storageKey);
          if (bytes.length != item.byteLength ||
              computeAuthoringBytesFingerprint(bytes,
                      logicalName: item.storageKey) !=
                  item.afterRevision) {
            throw const FormatException(
                'Published native creation inventory differs from its preparation.');
          }
        }
        await _validateLocal(plan.projectPath);
        _active(isCancelled);
      });
      _requireReceipt(plan, receipt);
      return NativeProjectCreationReceipt(
          projectPath: plan.projectPath,
          manifest: plan.prepared.manifest,
          transactionReceipt: receipt,
          inventoryFingerprint: plan.inventoryFingerprint);
    } on Object catch (error) {
      throw ProjectCreationException('project.native_creation_failed',
          'Prepared native creation failed; reserved destination retained for recovery: $error',
          residualPath: plan.projectPath);
    }
  }

  Future<NativeProjectCreationReceipt?> _replay(
      NativeProjectCreationPlan plan) async {
    final type =
        await FileSystemEntity.type(plan.projectPath, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.directory ||
        await Directory(plan.projectPath).resolveSymbolicLinks() !=
            plan.projectPath) {
      throw const ProjectCreationException('project.destination_exists',
          'The native creation destination is unavailable.');
    }
    final ledgerPath =
        '${plan.projectPath}/.pokemap/authoring/idempotency.jsonl';
    try {
      await const LocalProjectFileReader().readBytes(
          projectRoot: plan.projectPath,
          relativePath: '.pokemap/authoring/idempotency.jsonl');
    } on WorkspaceAccessException {
      throw const ProjectCreationException('project.destination_exists',
          'The destination is not this completed native creation.');
    }
    final lookup = await FileIdempotencyStore(filePath: ledgerPath)
        .lookupOperation(
            actorId: 'project-creator',
            projectId: 'project-${plan.operationId}',
            operationId: plan.operationId,
            now: _now);
    final receipt = lookup?.completed?.receipt;
    if (receipt == null ||
        receipt.status != AuthoringReceiptStatus.applied ||
        receipt.actionId != nativeProjectCreationActionId ||
        receipt.extensions['inventoryFingerprint'] !=
            plan.inventoryFingerprint) {
      throw const ProjectCreationException('project.destination_exists',
          'The destination is not this completed native creation.');
    }
    _requireReceipt(plan, receipt);
    await _verifyInventory(plan);
    final reader = const LocalProjectFileReader();
    for (final item in plan.prepared._inventory) {
      final bytes = await reader.readBytes(
          projectRoot: plan.projectPath, relativePath: item.storageKey);
      if (bytes.length != item.byteLength ||
          computeAuthoringBytesFingerprint(bytes,
                  logicalName: item.storageKey) !=
              item.afterRevision) {
        throw const ProjectCreationException(
            'project.replay_changed', 'The completed native creation changed.');
      }
    }
    await _validateLocal(plan.projectPath);
    return NativeProjectCreationReceipt(
        projectPath: plan.projectPath,
        manifest: plan.prepared.manifest,
        transactionReceipt: receipt,
        inventoryFingerprint: plan.inventoryFingerprint);
  }
}

void _requireReceipt(NativeProjectCreationPlan plan, AuthoringReceipt receipt) {
  if (receipt.extensions['planId'] != plan.planId ||
      receipt.extensions['operationId'] != plan.operationId ||
      receipt.beforeRevision != plan.beforeRevision ||
      receipt.afterRevision != plan.afterRevision ||
      canonicalAuthoringJson(receipt.diff.toJson()) !=
          canonicalAuthoringJson(plan.diff.toJson())) {
    throw const FormatException(
        'Native creation receipt differs from its exact plan.');
  }
}

Future<void> _verifyInventory(NativeProjectCreationPlan plan) async {
  final expected = plan.prepared._kit.files.keys.toSet();
  Future<void> visit(Directory directory) async {
    await for (final entry in directory.list(followLinks: false)) {
      final relative = entry.path
          .substring(plan.projectPath.length + 1)
          .replaceAll(Platform.pathSeparator, '/');
      if (relative == '.pokemap') {
        if (entry is! Directory) {
          throw const FormatException(
              'Unsafe native creation transaction directory.');
        }
        continue;
      }
      if (entry is Directory) {
        await visit(entry);
      } else if (entry is! File || !expected.remove(relative)) {
        throw const FormatException('Unexpected native creation resource.');
      }
    }
  }

  await visit(Directory(plan.projectPath));
  if (expected.isNotEmpty) {
    throw const FormatException(
        'Incomplete native creation resource inventory.');
  }
}

int _nonce = 0;
ProjectCreationRequest _request(
        NativePreparedProjectCreation prepared, String parent, String folder) =>
    ProjectCreationRequest(
        name: prepared._kit.manifest.name,
        folderName: folder,
        parentPath: parent,
        template: ProjectCreationTemplate.empty);
void _active(bool Function()? isCancelled) {
  if (isCancelled?.call() ?? false) throw const ProjectCreationCancelled();
}

String _id(String value) {
  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
    throw const FormatException('Invalid native Pokemon resource identity.');
  }
  return value;
}

Map<String, dynamic> _object(Object? value) =>
    Map<String, dynamic>.from(value as Map);
void _keys(Map<String, dynamic> value, Set<String> keys) {
  if (value.keys.any((key) => !keys.contains(key))) {
    throw const FormatException('Unknown native creation input field.');
  }
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

BorderSnapshotContentFrame _borderFrame(
    BorderVisualFrameSnapshot frame, List<int> bytes) {
  final decoder = image.PngDecoder();
  final info = decoder
      .startDecode(bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
  if (info == null ||
      info.width > 8192 ||
      info.height > 8192 ||
      info.width * info.height > 16777216 ||
      info.numFrames != 1) {
    throw const FormatException(
        'Native border image exceeds its decoded bounds.');
  }
  final decoded = decoder.decodeFrame(0);
  final rect = frame.sourceRectPx;
  if (decoded == null ||
      rect.right > decoded.width ||
      rect.bottom > decoded.height) {
    throw const FormatException('Native border frame exceeds its image.');
  }
  final rgba = Uint8List(rect.width * rect.height * 4);
  final transparent = frame.transparentColorArgb == null
      ? null
      : frame.transparentColorArgb! & 0xffffff;
  for (var y = 0; y < rect.height; y++) {
    for (var x = 0; x < rect.width; x++) {
      final pixel = decoded.getPixel(rect.x + x, rect.y + y);
      final offset = (y * rect.width + x) * 4;
      final red = pixel.r.toInt(),
          green = pixel.g.toInt(),
          blue = pixel.b.toInt();
      rgba[offset] = red;
      rgba[offset + 1] = green;
      rgba[offset + 2] = blue;
      rgba[offset + 3] = transparent == ((red << 16) | (green << 8) | blue)
          ? 0
          : pixel.a.toInt();
    }
  }
  return BorderSnapshotContentFrame(
      sourceRectPx: rect,
      durationMs: frame.durationMs,
      transparentColorArgb: frame.transparentColorArgb,
      rgbaBytes: rgba);
}

Future<void> _validateKit(ProjectCreationKit kit) async {
  final reader = _NativeCreationReader(kit.files);
  await _validateReader(reader, '/native-prepared-creation');
}

Future<void> _validateLocal(String path) =>
    _validateReader(const LocalProjectFileReader(), path);
Future<void> _validateReader(ProjectFileReader reader, String path) async {
  final handles = WorkspaceHandleStore();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [path], fileReader: reader);
  final opener =
      ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
  final opened = await opener.openProject(path);
  try {
    final loader = ProjectSnapshotLoader(handles: handles);
    final result =
        await AuthoringReadApi(openService: opener, snapshotLoader: loader)
            .validateProject(opened.projectHandle);
    if (!result.valid) {
      throw FormatException(
          'Native creation validation failed: ${jsonEncode(result.toJson())}');
    }
  } finally {
    handles.closeWorkspace(opened.workspaceHandle);
  }
}

final class _NativeCreationReader
    implements
        ProjectFileReader,
        ProjectDirectoryReader,
        ProjectResourceProbeReader {
  const _NativeCreationReader(this.files);
  final Map<String, List<int>> files;
  @override
  Future<String> canonicalizeDirectory(String path) async => path;
  @override
  Future<List<int>> readBytes(
          {required String projectRoot, required String relativePath}) async =>
      files[relativePath] ??
      (throw const WorkspaceAccessException('workspace.file_unavailable',
          'Native creation resource unavailable.'));
  @override
  Future<List<String>> listFiles(
          {required String projectRoot,
          required String relativeDirectory}) async =>
      [
        for (final path in files.keys)
          if (path.startsWith('$relativeDirectory/')) path
      ]..sort();
  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) async =>
      files.containsKey(relativePath)
          ? ProjectResourceProbe.exists(ProjectResourceIdentity(
              scope: projectRoot,
              relativePath: relativePath,
              byteLength: files[relativePath]!.length,
              modifiedAtMicros: 0))
          : const ProjectResourceProbe.missing();
}
