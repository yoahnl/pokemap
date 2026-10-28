import 'dart:convert';
import 'dart:isolate';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import '../ports/project_file_reader.dart';
import '../ports/transaction_file_gateway.dart';
import 'workspace_handle_store.dart';
import 'workspace_policy.dart';
import '../catalog_storage/catalog_storage_store.dart';
import '../transactions/local_transaction_file_gateway.dart';
import 'catalog/catalog_project_reader.dart';
import 'catalog_project_materialization.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/transaction_journal.dart';

final class ProjectOpenException implements Exception {
  const ProjectOpenException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ProjectOpenException($code): $message';
}

final class OpenedProject {
  const OpenedProject({
    required this.workspaceHandle,
    required this.projectHandle,
    required this.projectName,
    required this.fingerprint,
    required this.expiresAt,
    this.recoveryRequired=false,
    this.recoveryOperationIds=const [],
  });

  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final String projectName;
  final String fingerprint;
  final DateTime expiresAt;
  final bool recoveryRequired;
  final List<String> recoveryOperationIds;

  bool get readOnly => true;

  Map<String, Object?> toJson() => {
        'workspaceHandle': workspaceHandle.value,
        'projectHandle': projectHandle.value,
        'projectName': projectName,
        'fingerprint': fingerprint,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'readOnly': true,
        if(recoveryRequired) 'recoveryRequired':true,
        if(recoveryOperationIds.isNotEmpty) 'recoveryOperationIds':recoveryOperationIds,
      };
}

final class ProjectOpenService {
  ProjectOpenService({
    required WorkspacePolicy policy,
    required ProjectFileReader fileReader,
    required WorkspaceHandleStore handles,
    Set<String>? catalogMetadataFields,
    bool workshopScope = false,
  })  : _policy = policy,
        _fileReader = fileReader,
        _handles = handles,
        _workshopScope = workshopScope,
        _catalogMetadataFields = catalogMetadataFields == null
            ? null
            : Set.unmodifiable(catalogMetadataFields);

  final WorkspacePolicy _policy;
  final ProjectFileReader _fileReader;
  final WorkspaceHandleStore _handles;
  final bool _workshopScope;
  final Set<String>? _catalogMetadataFields;
  final Map<ProjectHandle, Future<CatalogProjectReader?> Function()>
      _catalogReaders = {};
  final Map<WorkspaceHandle, ProjectHandle> _catalogWorkspaces = {};
  final Map<ProjectHandle,Future<void> Function()> _readGuards={};

  Future<CatalogProjectReader?> catalogProject(ProjectHandle handle) async {
    _handles.requireActiveProject(handle);
    await _readGuards[handle]?.call();
    final reader = _catalogReaders[handle];
    return reader == null ? null : reader();
  }

  Future<OpenedProject> openProject(String projectRootPath) async {
    final canonicalRoot = await _policy.authorizeProjectRoot(projectRootPath);
    final manifestBytes = await _fileReader.readBytes(
      projectRoot: canonicalRoot,
      relativePath: 'project.json',
    );
    final descriptor = _catalogDescriptor(manifestBytes);
    final physicalRoot=await Directory(canonicalRoot).exists();
    Future<List<AuthoringTransactionJournal>> pendingCatalogTransactions() async {
      if(!physicalRoot) return const [];
      var transactionPath=canonicalRoot;
      for(final segment in const ['.pokemap','authoring','transactions']) {
        transactionPath='$transactionPath${Platform.pathSeparator}$segment';
        final type=await FileSystemEntity.type(transactionPath,followLinks:false);
        if(type==FileSystemEntityType.notFound) return const [];
        if(type!=FileSystemEntityType.directory) throw const CatalogStorageException('catalog.transaction_directory_invalid','The transaction directory is not a safe local directory.');
      }
      final gateway=await LocalTransactionFileGateway.open(projectRoot:canonicalRoot);
      return [for(final journal in await readPendingTransactionJournals(gateway, allowLegacyScan: true)) if(journal.status!=AuthoringTransactionStatus.committed && journal.status!=AuthoringTransactionStatus.compensated && journal.entries.any((entry)=>entry.storageKey==CatalogStorageStore.headStorageKey)) journal];
    }
    Future<void> requireReadableProject() async {
      if((await pendingCatalogTransactions()).isNotEmpty) throw const CatalogStorageException('catalog.recovery_required','Recover the pending catalog transaction before reading project content.');
    }
    final pendingAtOpen=await pendingCatalogTransactions();
    Future<CatalogProjectReader?> catalogReader() async {
      if(!const {'avelune.working-catalog','avelune.portable-catalog'}.contains(descriptor['format'])) return null;
      if(descriptor.isNotEmpty) {
        final observed=await _fileReader.readBytes(projectRoot:canonicalRoot,relativePath:'project.json');
        if(observed.length!=manifestBytes.length || !Iterable<int>.generate(observed.length).every((i)=>observed[i]==manifestBytes[i])) {
          throw const CatalogStorageException('catalog.revision_conflict','The project descriptor changed; reopen it before retrying.');
        }
      }
      return CatalogProjectReader.open(
          store: CatalogStorageStore(
              projectRoot: canonicalRoot,
              reader: _fileReader,
              gateway: await LocalTransactionFileGateway.open(
                  projectRoot: canonicalRoot)),
          descriptor: descriptor,
          allowRecoveryBootstrap: true,
          metadataFields: _catalogMetadataFields);
    }
    final catalog = await catalogReader();
    final ownedBytes = manifestBytes is Uint8List
        ? manifestBytes
        : Uint8List.fromList(manifestBytes);
    final workshopScope = _workshopScope;
    final inspection = catalog != null
        ? (name: catalog.name, fingerprint: catalog.revision)
        : ownedBytes.length >= 1024 * 1024
            ? await Isolate.run(() => _inspectProjectManifest(ownedBytes, workshopScope: workshopScope))
            : _inspectProjectManifest(ownedBytes, workshopScope: workshopScope);
    final fingerprint = inspection.fingerprint;
    final reader = _fileReader;
    final registered = _handles.registerProject(
      projectName: inspection.name,
      initialFingerprint: fingerprint,
      readBytes: (relativePath) => reader.readBytes(
        projectRoot: canonicalRoot,
        relativePath: relativePath,
      ),
      openRead: reader is ProjectResourceStreamReader &&
              (reader as ProjectResourceStreamReader).supportsStreamingResources
          ? (relativePath) => (reader as ProjectResourceStreamReader)
              .openRead(projectRoot: canonicalRoot, relativePath: relativePath)
          : null,
      // Only readers that can report identity cheaply enable snapshot reuse.
      readIdentity: reader is ProjectResourceIdentityReader
          ? (relativePath) =>
              (reader as ProjectResourceIdentityReader).readIdentity(
                projectRoot: canonicalRoot,
                relativePath: relativePath,
              )
          : null,
      listFiles: reader is ProjectDirectoryReader
          ? (relativeDirectory) => (reader as ProjectDirectoryReader).listFiles(
                projectRoot: canonicalRoot,
                relativeDirectory: relativeDirectory,
              )
          : null,
      probeResource: reader is ProjectResourceProbeReader
          ? (relativePath) =>
              (reader as ProjectResourceProbeReader).probeResource(
                projectRoot: canonicalRoot,
                relativePath: relativePath,
              )
          : null,
      materializeCatalogProject: catalog == null ? null : (expectedDescriptorBytes) async {
        if(expectedDescriptorBytes.length!=manifestBytes.length || !Iterable<int>.generate(manifestBytes.length).every((i)=>manifestBytes[i]==expectedDescriptorBytes[i])) {
          throw const CatalogStorageException('catalog.revision_conflict','The materialization descriptor changed.');
        }
        final current=await catalogReader();
        return current!.read((catalog) async {
          final head=current.readOnly?null:await current.store.readHead();
          if(!current.readOnly && head!=catalog.snapshot.root) {
            throw const CatalogStorageException('catalog.revision_conflict','The catalog changed before materialization.');
          }
          List<int>? headBytes;
          if(head!=null) {
            final streamReader=_fileReader;
            if(streamReader is! ProjectResourceStreamReader) throw const CatalogStorageException('catalog.streaming_required','Catalog materialization requires bounded stream reads.');
            final bytes=<int>[];
            await for(final chunk in (streamReader as ProjectResourceStreamReader).openRead(projectRoot:canonicalRoot,relativePath:CatalogStorageStore.headStorageKey)) {
              if(bytes.length+chunk.length>CatalogStorageStore.maximumHeadBytes) throw const CatalogStorageException('catalog.read_limit','The catalog head exceeds its read limit.');
              bytes.addAll(chunk);
            }
            final expected=CatalogStorageStore.encodeHead(head);
            if(bytes.length!=expected.length || !Iterable<int>.generate(bytes.length).every((i)=>bytes[i]==expected[i])) throw const CatalogStorageException('catalog.revision_conflict','The catalog head changed during materialization.');
            headBytes=bytes;
          }
          final project=await catalog.exportProject();
          final observed=await _fileReader.readBytes(projectRoot:canonicalRoot,relativePath:'project.json');
          if(observed.length!=expectedDescriptorBytes.length || !Iterable<int>.generate(observed.length).every((i)=>observed[i]==expectedDescriptorBytes[i])) {
            throw const CatalogStorageException('catalog.revision_conflict','The materialization descriptor changed.');
          }
          return ProjectCatalogMaterialization(manifest:project,descriptorRevision:computeAuthoringBytesFingerprint(expectedDescriptorBytes,logicalName:'project.json'),headBytes:headBytes);
        });
      },
      requireMutationRoot: (root) async {
        final observed = await _policy.authorizeProjectRoot(root);
        if (observed != canonicalRoot) {
          throw const WorkspaceHandleException(
            'workspace.mutation_binding_mismatch',
            'The mutation root differs from the opened project.',
          );
        }
      },
      requireReadableProject:physicalRoot?requireReadableProject:null,
      canReuseSnapshots: reader is ProjectSnapshotCacheIdentityReader,
    );
    if (catalog != null) _catalogReaders[registered.projectHandle] = catalogReader;
    _catalogWorkspaces[registered.workspaceHandle] = registered.projectHandle;
    if(physicalRoot) _readGuards[registered.projectHandle]=requireReadableProject;
    return OpenedProject(
      workspaceHandle: registered.workspaceHandle,
      projectHandle: registered.projectHandle,
      projectName: inspection.name,
      fingerprint: fingerprint,
      expiresAt: registered.expiresAt,
      recoveryRequired:pendingAtOpen.isNotEmpty || (catalog?.recoveryRequired??false),
      recoveryOperationIds:[for(final journal in pendingAtOpen) journal.operationId],
    );
  }

  bool closeWorkspace(WorkspaceHandle handle) {
    final project = _catalogWorkspaces.remove(handle);
    if (project != null) {
      _catalogReaders.remove(project);
      _readGuards.remove(project);
    }
    return _handles.closeWorkspace(handle);
  }
}

({String name, String fingerprint}) _inspectProjectManifest(List<int> bytes, {bool workshopScope = false}) {
  final manifest = workshopScope ? _decodeWorkshopHeader(bytes) : _decodeManifest(bytes);
  return (
    name: manifest.name,
    fingerprint: computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: bytes,
      ),
    ]),
  );
}

ProjectManifest _decodeWorkshopHeader(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException('Expected a JSON object.');
    final pokemon = decoded['pokemon'];
    if (pokemon is Map && pokemon['ruleset'] == null) {
      throw const ProjectOpenException(
        'project.pokemon_ruleset_required',
        'The project manifest requires an explicit Pokemon ruleset.',
      );
    }
    return ProjectManifest.fromJson({
      'name': decoded['name'],
      'version': decoded['version'],
      'maps': <Object?>[],
      'tilesets': <Object?>[],
      if (decoded['settings'] case final Map settings)
        'settings': {
          for (final key in const {'dimension', 'spatialCamera', 'tileWidth', 'tileHeight'})
            if (settings.containsKey(key)) key: settings[key],
        },
      'pokemon': pokemon is Map ? {'ruleset': pokemon['ruleset']} : pokemon,
    });
  } on ProjectOpenException {
    rethrow;
  } on Object {
    throw const ProjectOpenException(
      'project.manifest_invalid',
      'The project manifest is not valid PokeMap JSON.',
    );
  }
}

ProjectManifest _decodeManifest(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('Expected a JSON object.');
    }
    return ProjectManifest.fromJson(Map<String, dynamic>.from(decoded));
  } on Object {
    if (_isOtherwiseValidManifestMissingPokemonRuleset(bytes)) {
      throw const ProjectOpenException(
        'project.pokemon_ruleset_required',
        'The project manifest requires an explicit Pokemon ruleset.',
      );
    }
    throw const ProjectOpenException(
      'project.manifest_invalid',
      'The project manifest is not valid PokeMap JSON.',
    );
  }
}

bool _isOtherwiseValidManifestMissingPokemonRuleset(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) return false;
    final json = Map<String, dynamic>.from(decoded);
    final pokemonValue = json['pokemon'];
    if (pokemonValue is! Map) return false;
    final pokemon = Map<String, dynamic>.from(pokemonValue);
    if (pokemon.containsKey('ruleset') && pokemon['ruleset'] != null) {
      return false;
    }
    pokemon['ruleset'] = PokemonRulesetProfile.pokeMapBetaV1.toJson();
    json['pokemon'] = pokemon;
    ProjectManifest.fromJson(json);
    return true;
  } on Object {
    return false;
  }
}

Map<String, Object?> _catalogDescriptor(List<int> bytes) {
  if (bytes.length > 4096) return const {};
  try {
    final value = jsonDecode(utf8.decode(bytes));
    if (value is Map && value['format'] is String) {
      return Map<String, Object?>.from(value);
    }
  } on Object {return const {};}
  return const {};
}
