import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:map_distribution/map_distribution.dart';
import 'package:map_core/map_core.dart';

import '../domains/assets/resource_pack_import_preparer.dart';
import '../domains/assets/resource_pack_projection.dart';
import '../domains/assets/asset_store.dart';
import '../support/authoring_fingerprint.dart';

import '../application/resource_pack_job_service.dart';
import '../contracts/job_contracts.dart';
import '../contracts/json_contract_support.dart';
import '../contracts/query_request.dart';
import '../infrastructure/local_resource_pack_store.dart';
import '../ports/file_backed_payload_store.dart';
import '../workspace/project_snapshot_loader.dart';
import '../workspace/workspace_handle_store.dart';
import 'local_map_authoring_mutation_api.dart';
import 'resource_pack_transfer_api.dart';

final class LocalResourcePackTransferApi
    implements ResourcePackTransferApiPort {
  LocalResourcePackTransferApi({
    required this.mutations,
    required this.snapshotLoader,
    ResourcePackInspection Function(RandomAccessPackageSource)? inspectSource,
  }) : _inspectSource = inspectSource ?? _inspect;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshotLoader;
  final ResourcePackInspection Function(RandomAccessPackageSource)
  _inspectSource;
  final Map<ProjectHandle, _TransferSession> _sessions = {};
  final Set<ProjectHandle> _closingProjects = {};

  @override
  Future<void> requireSynchronousOperationAllowed(
    ProjectHandle projectHandle, {
    required String operation,
    String? planId,
    String? operationId,
    String? entryId,
  }) async {
    _session(projectHandle);
    if (await mutations.resourcePackRequiresJob(
      projectHandle,
      operation: operation,
      planId: planId,
      operationId: operationId,
      entryId: entryId,
    )) {
      throw ResourcePackTransferException(
        'resource_pack.job_required',
        'This canonical resource pack operation requires an asynchronous job.',
        details: {
          'verb': operation == 'apply'
              ? 'start_apply'
              : operation == 'undo'
              ? 'start_history'
              : 'start_recovery',
        },
      );
    }
  }

  _TransferSession _session(ProjectHandle project) {
    if (_closingProjects.contains(project)) _fail('session_closed');
    snapshotLoader.requireActiveProject(project);
    mutations.requireResourcePackRead(project);
    return _sessions.putIfAbsent(project, () {
      final preparer = mutations.resourcePackImports(project);
      return _TransferSession(
        project,
        preparer.workspaceHandle,
        preparer.scope,
        mutations.resourcePackInitialRevision(project),
        mutations.resourcePackPayloadStore(project),
        ResourcePackJobService(
          requireActive: () {
            snapshotLoader.requireActiveProject(project);
            mutations.requireResourcePackRead(project);
          },
        ),
      );
    });
  }

  @override
  Future<Map<String, Object?>> transfer(
    ProjectHandle projectHandle, {
    required String verb,
    Map<String, Object?> input = const {},
  }) async => freezeContractJsonObject(await _transfer(projectHandle, verb: verb, input: input),
      field: 'resourcePackTransfer');

  Future<Map<String, Object?>> _transfer(ProjectHandle projectHandle, {
    required String verb, Map<String, Object?> input = const {},
  }) async {
    final session = _session(projectHandle);
    final args = Map<String, dynamic>.from(input);
    switch (verb) {
      case 'stage':
        _keys(args, const {'sourcePath'});
        final path = _string(args, 'sourcePath', max: 4096);
        return _start(session, 'stage', {}, (job) async {
          job.progress('staging');
          var reported = 0;
          FileBackedPayloadLease? staged;
          try {
            staged = await session.store.stageFile(
              scope: session.scope,
              sourcePath: path,
              checkCancelled: job.checkCancelled,
              onProgress: (copied) {
                if (copied - reported >= 8 * 1024 * 1024) {
                  reported = copied;
                  job.progress('staging', counters: {'copiedBytes': copied});
                }
              },
            );
            job.checkCancelled();
            final handle = _token('archive');
            session.archives[handle] = staged;
            staged = null;
            final payload = session.archives[handle]!.payload;
            return {
              'archiveHandle': handle,
              'byteLength': payload.byteLength,
              'rawSha256': payload.rawSha256,
            };
          } finally {
            if (staged != null) {
              await session.store.release(
                scope: session.scope,
                leaseId: staged.leaseId,
              );
            }
          }
        });
      case 'inspect':
        _keys(args, const {'archiveHandle'});
        final handle = _string(args, 'archiveHandle');
        final archive = _archive(session, handle);
        return _start(session, 'inspect', {'archiveHandle': handle}, (
          job,
        ) async {
          final lease = await session.store.retain(
            scope: session.scope,
            handle: archive.payload.handle,
            purpose: FileBackedPayloadPurpose.job,
          );
          try {
            job.progress('inspecting');
            final proof = await mutations
                .resourcePackImports(projectHandle)
                .inspectArchive(
                  lease.payload.handle,
                  inspector: _inspectSource,
                );
            final inspected = proof.inspection;
            job.checkCancelled();
            final id = _token('inspection');
            session.inspections[id] = _Inspection(id, lease, inspected, proof);
            return _inspectionSummary(session, session.inspections[id]!);
          } on Object {
            await session.store.release(
              scope: session.scope,
              leaseId: lease.leaseId,
            );
            rethrow;
          }
        }, sourceHandle: archive.payload.handle);
      case 'entries':
        _keys(args, const {
          'inspectionHandle',
          'selectionHandle',
          'section',
          'filter',
          'cursor',
          'limit',
        });
        final owner = args['selectionHandle'] ?? args['inspectionHandle'];
        if (owner is! String ||
            (args.containsKey('selectionHandle') ==
                args.containsKey('inspectionHandle'))) {
          _fail('owner_required');
        }
        final selection = session.selections[owner];
        final inspection = session.inspections[owner];
        if (selection == null && inspection == null) _fail('handle_unknown');
        final section = args['section'] ?? 'resources';
        if (!const {'resources', 'families', 'authors', 'sources'}.contains(section)) _fail('section_invalid');
        final source = inspection ?? selection?.inspection;
        if (section != 'resources' && source == null) _fail('section_unavailable');
        final rows = section == 'resources'
            ? _filterRows(selection?.rows ?? inspection!.rows, _filter(args), selection)
            : _inspectionSection(source!, section as String);
        return _page(
          session,
          owner,
          selection?.revision ?? inspection!.value.archiveRawSha256,
          rows,
          args,
          'resourcePackEntry',
        );
      case 'selection.create':
        _keys(args, const {'mode', 'inspectionHandle'});
        final mode = _string(args, 'mode');
        final id = _token('selection');
        final List<Map<String, Object?>> rows;
        FileBackedPayloadLease? lease;
        _Inspection? inspection;
        String sourceRevision;
        if (mode == 'archive') {
          inspection = session.inspections[_string(args, 'inspectionHandle')];
          if (inspection == null) _fail('inspection_unknown');
          lease = await session.store.retain(
            scope: session.scope,
            handle: inspection.lease.payload.handle,
          );
          rows = inspection.rows;
          sourceRevision = inspection.value.archiveRawSha256;
        } else if (mode == 'native' && args['inspectionHandle'] == null) {
          final snapshot = await snapshotLoader.load(
            projectHandle,
            policy: ProjectSnapshotLoadPolicy.editorReadProjection,
          );
          rows = _rootRows(snapshot.manifest);
          sourceRevision = snapshot.revision;
        } else {
          _fail('selection_mode_invalid');
        }
        final selected = _Selection(
          id,
          mode,
          rows,
          sourceRevision,
          inspection,
          lease,
        );
        session.selections[id] = selected;
        return _selectionSummary(session, selected);
      case 'selection.patch':
        _keys(args, const {'selectionHandle', 'revision', 'add', 'remove'});
        final selected = _selection(session, args);
        final add = _refs(args['add'] ?? const []);
        final remove = _refs(args['remove'] ?? const []);
        if (add.length + remove.length > 200) {
          _fail('selection_patch_too_large');
        }
        final allowed = {for (final row in selected.rows) _rowKey(row)};
        if (!allowed.containsAll(add) || !allowed.containsAll(remove)) {
          _fail('selection_ref_unknown');
        }
        selected.selected.removeAll(remove);
        selected.selected.addAll(add);
        selected.version++;
        return _selectionSummary(session, selected);
      case 'selection.select_filtered':
        _keys(args, const {'selectionHandle', 'revision', 'filter'});
        final selected = _selection(session, args);
        selected.selected.addAll(
          _filterRows(selected.rows, _filter(args), selected).map(_rowKey),
        );
        selected.version++;
        return _selectionSummary(session, selected);
      case 'prepare':
        _keys(args, const {
          'selectionHandle',
          'revision',
          'expectedRevision',
          'conflictPolicy',
        });
        final selected = _selection(session, args);
        if (selected.mode != 'archive' || selected.selected.isEmpty) {
          _fail('selection_invalid');
        }
        final revision = _string(args, 'expectedRevision');
        final policyName = args['conflictPolicy'] ?? 'preserveProject';
        final conflictPolicy = ResourcePackConflictPolicy.values
            .where((p) => p.name == policyName)
            .firstOrNull;
        if (conflictPolicy == null) _fail('conflict_policy_invalid');
        final refs = selected.selected.toList();
        final inspected = selected.inspection!;
        return _start(session, 'prepare', {'selectionHandle': selected.id}, (
          job,
        ) async {
          final preparer = mutations.resourcePackImports(projectHandle);
          ResourcePackImportSelection? canonical;
          ResourcePackPreparedImport? prepared;
          try {
            job.progress('preparing');
            canonical = await preparer.selectInspected(
              proof: inspected.proof,
              roots: [
                for (final key in refs)
                  if ((jsonDecode(key) as List)[0] != 'smartTilePattern')
                    _portableRef(key),
              ],
              smartTilePatternIds: [
                for (final key in refs)
                  if ((jsonDecode(key) as List)[0] == 'smartTilePattern')
                    (jsonDecode(key) as List)[1] as String,
              ],
            );
            job.checkCancelled();
            prepared = await preparer.prepare(
              selectionHandle: canonical.handle,
              selectionRevision: canonical.revision,
              expectedRevision: revision,
              conflictPolicy: conflictPolicy,
              checkCancelled: job.checkCancelled,
            );
            job.checkCancelled();
            final preview = _token('preview');
            session.previews[preview] = prepared.review.rows;
            if (prepared.preparedImportHandle != null) {
              session.prepared.add(prepared.preparedImportHandle!);
            }
            return {
              'status': prepared.status.name,
              if (prepared.preparedImportHandle != null)
                'preparedImportHandle': prepared.preparedImportHandle,
              'previewHandle': preview,
              'previewUri': _uri(session, 'resourcePackPreview', preview),
              'resourceCount': prepared.review.summary['resourceCount'],
              'summary': prepared.review.summary,
              'conflictCount': prepared.conflicts.length,
            };
          } on Object {
            if (prepared?.preparedImportHandle != null) {
              await preparer.discardPrepared(prepared!.preparedImportHandle!);
            }
            rethrow;
          } finally {
            if (canonical != null) {
              await preparer.discardSelection(canonical.handle);
            }
          }
        }, sourceHandle: inspected.lease.payload.handle);
      case 'preview':
        _keys(args, const {'previewHandle', 'cursor', 'limit'});
        final id = _string(args, 'previewHandle');
        final rows = session.previews[id];
        if (rows == null) _fail('preview_unknown');
        return _page(session, id, id, rows, args, 'resourcePackPreview');
      case 'start_apply':
        _keys(args, const {'planId', 'operationId', 'confirmationToken'});
        final planId = _string(args, 'planId');
        final operation = _string(args, 'operationId');
        final confirmation = args['confirmationToken'];
        if (confirmation != null && confirmation is! String) {
          _fail('input_invalid');
        }
        return _start(
          session,
          'import',
          {'planId': planId, 'operationId': operation},
          (job) async {
            if (!await mutations.resourcePackRequiresJob(projectHandle,
                operation: 'apply', planId: planId, operationId: operation)) {
              _fail('plan_kind_invalid');
            }
            job.checkCancelled();
            job.progress('applying');
            return (await mutations.applyMutation(
              projectHandle,
              planId: planId,
              operationId: operation,
              confirmationToken: confirmation as String?,
              beforeReservation: job.enterFinalization,
              preparationCheck: job.checkCancelled,
            )).toJson();
          },
        );
      case 'export':
        mutations.requireResourcePackExport(projectHandle);
        _keys(args, const {
          'selectionHandle',
          'revision',
          'expectedRevision',
          'metadata',
          'author',
          'sourceUrl',
          'licenseText',
          'acknowledgeOrganizationRemoval',
        });
        final selected = _selection(session, args);
        if (selected.mode != 'native' || selected.selected.isEmpty) {
          _fail('selection_invalid');
        }
        final expected = _string(args, 'expectedRevision');
        if (selected.sourceRevision != expected) _fail('selection_stale');
        final metadataJson = args['metadata'];
        if (metadataJson is! Map) _fail('metadata_invalid');
        final metadata = ResourcePackMetadata.fromJson(
          Map<String, Object?>.from(metadataJson),
        );
        final author = _string(args, 'author', max: 256);
        final sourceUrl = args['sourceUrl'];
        final license = args['licenseText'];
        final acknowledge = args['acknowledgeOrganizationRemoval'] ?? false;
        if ((sourceUrl != null &&
                (sourceUrl is! String || sourceUrl.length > 4096)) ||
            (license != null &&
                (license is! String || license.length > 32000)) ||
            acknowledge is! bool) {
          _fail('metadata_invalid');
        }
        final refs = selected.selected.toList();
        return _start(session, 'export', {'selectionHandle': selected.id}, (
          job,
        ) async {
          final leases = <FileBackedPayloadLease>[];
          OwnedResourcePackExport? artifact;
          String? pendingPayloadRef;
          try {
            job.progress('selectingNativeClosure');
            final snapshot = await snapshotLoader.load(
              projectHandle,
              policy: ProjectSnapshotLoadPolicy.editorReadProjection,
            );
            if (snapshot.revision != expected) _fail('project_stale');
            final roots = [
              for (final key in refs)
                if ((jsonDecode(key) as List)[0] != 'smartTilePattern')
                  NativeResourcePackRef(
                    kind: ResourcePackKind.values.singleWhere(
                      (kind) => kind.name == (jsonDecode(key) as List)[0],
                    ),
                    id: (jsonDecode(key) as List)[1] as String,
                  ),
            ];
            final patterns = [
              for (final key in refs)
                if ((jsonDecode(key) as List)[0] == 'smartTilePattern')
                  (jsonDecode(key) as List)[1] as String,
            ];
            final catalogBytes = snapshot.findResourceBytes(
              assetCatalogResourceIdentity,
            );
            final catalog = catalogBytes == null
                ? AssetCatalog()
                : AssetCatalog.fromJson(
                    Map<String, dynamic>.from(
                      jsonDecode(utf8.decode(catalogBytes)) as Map,
                    ),
                  );
            final sourceDigests = <String, String>{
              for (final entry in snapshot.resourceStorageKeys.entries)
                if (snapshot.storedResources[entry.key] != null)
                  entry.value: snapshot.storedResources[entry.key]!.rawSha256,
            };
            final candidates = [
              for (final record in catalog.records)
                NativeResourcePackFile(
                  id: record.id,
                  logicalPath: record.logicalPath,
                  byteLength: record.artifact.byteLength,
                  rawSha256: sourceDigests[record.logicalPath] ?? '',
                  mediaType: record.artifact.mediaType,
                  openRead: () => snapshotLoader.openResourceStream(
                    projectHandle,
                    record.logicalPath,
                  ),
                ),
            ];
            final required = await const ResourcePackProjectionBuilder()
                .selectedFileIds(
                  manifest: snapshot.manifest,
                  roots: roots,
                  files: candidates,
                  smartTilePatternIds: patterns,
                );
            final files = <(String, String, StoredFilePayload, String)>[];
            for (final file in candidates.where(
              (file) => required.contains(file.id),
            )) {
              job.checkCancelled();
              if (file.rawSha256.isEmpty) _fail('native_source_unavailable');
              final lease = await session.store.stage(
                scope: session.scope,
                chunks: file.openRead(),
                byteLength: file.byteLength,
                expectedRawSha256: file.rawSha256,
                checkCancelled: job.checkCancelled,
              );
              leases.add(lease);
              files.add((
                file.id,
                file.logicalPath,
                lease.payload,
                file.mediaType,
              ));
            }
            job.progress(
              'exporting',
              counters: {
                'selectedRoots': roots.length,
                'sourceFiles': files.length,
              },
            );
            artifact =
                await CanonicalResourcePackExportService(
                  store: session.store,
                  scope: session.scope,
                ).exportNative(
                  manifest: snapshot.manifest,
                  roots: roots,
                  smartTilePatternIds: patterns,
                  files: files,
                  metadata: metadata,
                  author: author,
                  expectedRevision: expected,
                  sourceUrl: sourceUrl as String?,
                  licenseText: license as String?,
                  acknowledgeOrganizationRemoval: acknowledge,
                  checkCancelled: job.checkCancelled,
                  readCurrentRevision: () async => (await snapshotLoader.load(
                    projectHandle,
                    policy: ProjectSnapshotLoadPolicy.editorReadProjection,
                  )).revision,
                );
            job.checkCancelled();
            final id = _token('artifact');
            final payload = artifact.payload;
            job.progress('preparingPayload');
            final reference = await mutations.resourcePackExportPayload(
              projectHandle,
              payload,
              checkCancelled: job.checkCancelled,
            );
            pendingPayloadRef = reference['payloadRef']! as String;
            job.checkCancelled();
            session.artifacts[id] = _ExportArtifact(
              artifact,
              pendingPayloadRef,
            );
            pendingPayloadRef = null;
            artifact = null;
            return {
              'artifactHandle': id,
              'payloadRef': reference['payloadRef'],
              'rawSha256': payload.rawSha256,
              'byteLength': payload.byteLength,
              'selectedRoots': roots.length,
              'fileCount': files.length,
            };
          } finally {
            if (pendingPayloadRef != null) {
              await mutations.resourcePackReleaseExportPayload(
                projectHandle,
                pendingPayloadRef,
              );
            }
            await artifact?.dispose();
            for (final lease in leases) {
              await session.store.release(
                scope: session.scope,
                leaseId: lease.leaseId,
              );
            }
          }
        });
      case 'read_payload':
        _keys(args, const {'payloadRef', 'offset', 'length'});
        final ref = _string(args, 'payloadRef');
        final length = _integer(args, 'length');
        final offset = _integer(args, 'offset');
        if (length < 1 || length > 128 * 1024) _fail('chunk_invalid');
        return (await mutations.readMutationPayloadChunk(
          projectHandle,
          payloadRef: ref,
          offset: offset,
          byteLength: length,
        )).toJson();
      case 'start_history':
        _keys(args, const {
          'operation',
          'entryId',
          'expectedHeadEntryId',
          'expectedRevision',
          'operationId',
        });
        final operation = _string(args, 'operation');
        if (!const {'undo', 'redo', 'revert'}.contains(operation)) {
          _fail('history_operation_invalid');
        }
        final entry = _string(args, 'entryId');
        final operationId = _string(args, 'operationId');
        final expectedRevision = _string(args, 'expectedRevision');
        final head = args['expectedHeadEntryId'];
        if (head != null && head is! String) _fail('input_invalid');
        return _start(
          session,
          operation,
          {'entryId': entry, 'operationId': operationId},
          (job) async {
            job.progress('planningHistory');
            return (await mutations.resourcePackHistory(
              projectHandle,
              operation: operation,
              entryId: entry,
              operationId: operationId,
              expectedRevision: expectedRevision,
              expectedHeadEntryId: head as String?,
              beforeReservation: job.enterFinalization,
              preparationCheck: job.checkCancelled,
            )).toJson();
          },
        );
      case 'recovery_status':
        _keys(args, const {});
        final pending = await mutations.resourcePackPending(projectHandle);
        return {
          'recoveryRequired': pending.any(
            (p) =>
                p.disposition.name == 'resumable' ||
                p.disposition.name == 'blocked',
          ),
          'transactions': [
            for (final entry in pending.take(200)) entry.toJson(),
          ],
        };
      case 'start_recovery':
        _keys(args, const {'operationId'});
        final operation = _string(args, 'operationId');
        return _start(session, 'recover', {'operationId': operation}, (
          job,
        ) async {
          job.progress('checkingRecovery');
          return (await mutations.resourcePackRecover(
            projectHandle,
            operationId: operation,
            beforeRecovery: job.enterFinalization,
          )).toJson();
        });
      case 'get':
        _keys(args, const {'jobId'});
        return session.jobs.result(_string(args, 'jobId'));
      case 'events':
        _keys(args, const {'jobId', 'afterSequence', 'cursor'});
        final jobId = _string(args, 'jobId');
        var after = _integer(args, 'afterSequence', fallback: 0);
        final cursor = args['cursor'];
        if (cursor != null) {
          final found = session.eventCursors[cursor];
          if (found == null || found.$1 != jobId) _fail('cursor_invalid');
          after = found.$2;
        }
        final rows = await session.jobs.events(jobId, afterSequence: after);
        final snapshot = await session.jobs.get(jobId);
        final more =
            rows.isNotEmpty && rows.last.sequence < snapshot.lastEventSequence;
        final next = more ? _token('events') : null;
        if (next != null) {
          session.eventCursors[next] = (jobId, rows.last.sequence);
        }
        return {
          'events': [for (final row in rows) row.toJson()],
          'returned': rows.length,
          if (next != null) 'nextCursor': next,
        };
      case 'cancel':
        _keys(args, const {'jobId'});
        final result = await session.jobs.cancel(
          _string(args, 'jobId'),
          timeout: const Duration(seconds: 1),
        );
        return {
          'jobId': result.jobId,
          'state': result.state.name,
          'bounded': result.bounded,
          'timeoutMilliseconds': result.timeoutMilliseconds,
        };
      case 'release':
        _keys(args, const {'handle'});
        final handle = _string(args, 'handle');
        if (session.previews.remove(handle) != null) {
          session.cursors.removeWhere((_, cursor) => cursor.$1 == handle);
          return {'released': true};
        }
        final artifact = session.artifacts.remove(handle);
        if (artifact != null) {
          await mutations.resourcePackReleaseExportPayload(
            projectHandle,
            artifact.payloadRef,
          );
          await artifact.owner.dispose();
          return {'released': true};
        }
        final archive = session.archives.remove(handle);
        final inspection = session.inspections.remove(handle);
        final selection = session.selections.remove(handle);
        final prepared = session.prepared.remove(handle);
        if (prepared) {
          await mutations
              .resourcePackImports(projectHandle)
              .discardPrepared(handle);
          return {'released': true};
        }
        if (selection != null) {
          if (selection.lease != null) {
            await session.store.release(
              scope: session.scope,
              leaseId: selection.lease!.leaseId,
            );
          }
          return {'released': true};
        }
        if (archive == null && inspection == null) _fail('handle_unknown');
        await session.store.release(
          scope: session.scope,
          leaseId: (archive ?? inspection!.lease).leaseId,
        );
        return {'released': true};
      default:
        _fail('verb_unsupported');
    }
  }

  Future<Map<String, Object?>> _start(
    _TransferSession session,
    String kind,
    Map<String, Object?> input,
    ResourcePackJobWork work, {
    String? sourceHandle,
  }) async {
    final revision = session.revision ??= mutations.resourcePackInitialRevision(
      session.project,
    );
    final pin = sourceHandle == null
        ? null
        : session.store.retainForJob(
            scope: session.scope,
            handle: sourceHandle,
          );
    Future<void> releasePin() async {
      if (pin != null) {
        await session.store.release(scope: session.scope, leaseId: pin.leaseId);
      }
    }

    late final AuthoringJobSnapshot result;
    try {
      result = await session.jobs.startWork(
        AuthoringJobRequest(
          requestId: _token('request'),
          kind: 'resource_pack.$kind',
          projectId: session.scope.projectId,
          projectRevision: revision,
          input: input,
        ),
        work,
        onSettled: releasePin,
      );
    } on Object {
      await releasePin();
      rethrow;
    }
    return {
      'jobId': result.jobId,
      'snapshot': result.toJson(),
      'uri': _uri(session, 'resourcePackJob', result.jobId),
    };
  }

  @override
  Future<Map<String, Object?>> queryTransfer(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  ) async => freezeContractJsonObject(await _queryTransfer(projectHandle, request),
      field: 'resourcePackQuery');

  Future<Map<String, Object?>> _queryTransfer(ProjectHandle projectHandle,
      AuthoringQueryRequest request) async {
    final session = _session(projectHandle);
    if (!resourcePackTemporaryKinds.contains(request.resourceKind)) {
      _fail('kind_invalid');
    }
    if (request.operation != AuthoringQueryOperation.get ||
        request.ids.length != 1 ||
        (request.filters.isNotEmpty &&
            request.resourceKind != 'resourcePackEntry') ||
        request.fieldMask.isNotEmpty ||
        request.searchTerm != null ||
        request.sort.isNotEmpty ||
        request.extensions.isNotEmpty ||
        (request.cursor != null &&
            request.resourceKind != 'resourcePackEntry' &&
            request.resourceKind != 'resourcePackPreview')) {
      _fail('query_invalid');
    }
    final id = request.ids.single;
    final Map<String, Object?> value;
    switch (request.resourceKind) {
      case 'resourcePackJob':
        value = session.jobs.result(id);
      case 'resourcePackSelection':
        final selected = session.selections[id];
        if (selected == null) _fail('selection_unknown');
        value = _selectionSummary(session, selected);
      case 'resourcePackEntry':
        final selected = session.selections[id];
        final inspected = session.inspections[id];
        if (selected == null && inspected == null) _fail('handle_unknown');
        return _queryPage(
          _page(
            session,
            id,
            selected?.revision ?? inspected!.value.archiveRawSha256,
            _filterRows(
              selected?.rows ?? inspected!.rows,
              _filter({'filter': request.filters}),
              selected,
            ),
            {
              'limit': request.pageSize,
              'filter': request.filters,
              if (request.cursor != null) 'cursor': request.cursor,
            },
            'resourcePackEntry',
          ),
        );
      case 'resourcePackPreview':
        final rows = session.previews[id];
        if (rows == null) _fail('preview_unknown');
        return _queryPage(
          _page(session, id, id, rows, {
            'limit': request.pageSize,
            if (request.cursor != null) 'cursor': request.cursor,
          }, 'resourcePackPreview'),
        );
      case 'resourcePackInspection':
        final inspected = session.inspections[id];
        if (inspected == null) _fail('inspection_unknown');
        value = _inspectionSummary(session, inspected);
      default:
        _fail('handle_unknown');
    }
    return {
      'snapshotRevision': session.revision!,
      'items': [value],
      'returned': 1,
      'totalAvailable': 1,
    };
  }

  @override
  Future<void> closeTransferWorkspace(WorkspaceHandle workspaceHandle) async {
    final entries = _sessions.entries
        .where((entry) => entry.value.workspace == workspaceHandle.value)
        .toList();
    for (final entry in entries) {
      _closingProjects.add(entry.key);
      await entry.value.jobs.close();
      _sessions.remove(entry.key);
      for (final artifact in entry.value.artifacts.values) {
        await mutations.resourcePackReleaseExportPayload(
          entry.key,
          artifact.payloadRef,
        );
        await artifact.owner.dispose();
      }
      for (final lease in [
        ...entry.value.archives.values,
        ...entry.value.inspections.values.map((value) => value.lease),
        ...entry.value.selections.values
            .map((value) => value.lease)
            .whereType<FileBackedPayloadLease>(),
      ]) {
        await entry.value.store.release(
          scope: entry.value.scope,
          leaseId: lease.leaseId,
        );
      }
    }
  }
}

final class _TransferSession {
  _TransferSession(
    this.project,
    this.workspace,
    this.scope,
    this.revision,
    this.store,
    this.jobs,
  );
  final ProjectHandle project;
  final String workspace;
  final FileBackedPayloadScope scope;
  final LocalResourcePackStore store;
  final ResourcePackJobService jobs;
  String? revision;
  final Map<String, FileBackedPayloadLease> archives = {};
  final Map<String, _Inspection> inspections = {};
  final Map<String, _Selection> selections = {};
  final Map<String, List<Map<String, Object?>>> previews = {};
  final Set<String> prepared = {};
  final Map<String, _ExportArtifact> artifacts = {};
  final Map<String, (String, String, String, int)> cursors = {};
  final Map<String, (String, int)> eventCursors = {};
}

final class _Inspection {
  _Inspection(this.id, this.lease, this.value, this.proof);
  final String id;
  final FileBackedPayloadLease lease;
  final ResourcePackInspection value;
  final ResourcePackInspectedArchive proof;
  late final rows = _rootRows(value.catalog);
}

FileBackedPayloadLease _archive(_TransferSession session, String handle) =>
    session.archives[handle] ??
    (throw const ResourcePackTransferException(
      'resource_pack.archive_unknown',
      'The archive is unknown in this session.',
    ));
Map<String, Object?> _inspectionSummary(
  _TransferSession session,
  _Inspection value,
) => {
  'inspectionHandle': value.id,
  'archiveRawSha256': value.value.archiveRawSha256,
  'fileCount': value.value.catalog.files.length,
  'pack': {'id': value.value.manifest.pack.id, 'name': value.value.manifest.pack.name, 'version': value.value.manifest.pack.version, 'universeId': value.value.manifest.pack.universeId, 'provenance': value.value.manifest.pack.provenance},
  'authorCount': value.value.manifest.pack.authors.length,
  'sourceCount': value.value.catalog.provenance.length,
  'archiveBytes': value.value.archiveBytes,
  'payloadBytes': value.value.payloadBytes,
  'requiredCapabilities': value.value.manifest.compatibility.requiredCapabilities,
  'provenanceStatus': value.value.provenanceStatus.name,
  'entriesUri': _uri(session, 'resourcePackEntry', value.id),
  'uri': _uri(session, 'resourcePackInspection', value.id),
};
List<Map<String, Object?>> _inspectionSection(_Inspection inspection, String section) => switch (section) {
  'families' => [for (final family in inspection.value.catalog.resourceLibraryCatalog.effectiveFamilies) {'kind': 'resourceFamily', 'id': family.id, ..._entryLabel(family.name)}],
  'authors' => [for (final author in inspection.value.manifest.pack.authors) {'kind': 'author', ..._entryLabel(author)}],
  'sources' => [for (final source in inspection.value.catalog.provenance) {'kind': 'source', ..._entryLabel(source.author), if (source.sourceUrl != null) 'sourceUrl': source.sourceUrl, 'licenseCount': source.licenseIds.length}],
  _ => throw const FormatException('Unknown inspection section'),
};
Map<String, Object?> _entryLabel(String value) {
  final characters = value.runes;
  final length = characters.length;
  return {'label': String.fromCharCodes(characters.take(160)), 'labelComplete': length <= 160, 'labelLength': length};
}
ResourcePackInspection _inspect(RandomAccessPackageSource source) =>
    const ResourcePackInspector().inspectSourceSync(source);
String _uri(_TransferSession session, String kind, String handle) =>
    'pokemap://project/${session.project.value}/resource-pack/$kind/$handle';
void _keys(Map<String, dynamic> args, Set<String> allowed) {
  rejectUnknownContractKeys(args, allowed);
  if (utf8.encode(jsonEncode(args)).length > 64 * 1024) {
    _fail('input_too_large');
  }
}

String _string(Map<String, dynamic> args, String name, {int max = 128}) {
  final value = requireContractString(args[name], name);
  if (value.length > max) _fail('input_too_large');
  return value;
}

int _integer(Map<String, dynamic> args, String name, {int? fallback}) {
  final value = args[name] ?? fallback;
  if (value is! int || value < 0) {
    throw FormatException('$name must be nonnegative.');
  }
  return value;
}

Never _fail(String code) => throw ResourcePackTransferException(
  'resource_pack.$code',
  'The scoped pack transfer request was rejected.',
);
String _token(String prefix) {
  final random = Random.secure();
  return '${prefix}_${List.generate(24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}

final class _Selection {
  _Selection(
    this.id,
    this.mode,
    this.rows,
    this.sourceRevision,
    this.inspection,
    this.lease,
  );
  final String id;
  final String mode;
  final List<Map<String, Object?>> rows;
  final String sourceRevision;
  final _Inspection? inspection;
  final FileBackedPayloadLease? lease;
  final Set<String> selected = {};
  int version = 0;
  String get revision => computeAuthoringJsonFingerprint({
    'selection': id,
    'version': version,
  }, logicalName: 'resource-pack-selection');
}

List<Map<String, Object?>> _rootRows(dynamic source) {
  final groups = <String, Iterable<dynamic>>{
    'tileset': source.tilesets as Iterable<dynamic>,
    'element': source.elements as Iterable<dynamic>,
    'model3d': source.models3d as Iterable<dynamic>,
    'character': source.characters as Iterable<dynamic>,
    'environmentPreset': source.environmentPresets as Iterable<dynamic>,
    'smartTilePreset': source.smartTileCatalog.presets as Iterable<dynamic>,
    'smartTilePattern': source.smartTileCatalog.patterns as Iterable<dynamic>,
    'borderBlueprint': source.borderCatalog.records as Iterable<dynamic>,
  };
  final library = source.resourceLibraryCatalog as ResourceLibraryCatalog;
  final metadata = {for (final entry in library.entries) entry.identity: entry};
  final families = {
    for (final family in library.effectiveFamilies) family.id: family,
  };
  List<String> lineage(String? family) {
    final result = <String>[];
    while (family != null && !result.contains(family)) {
      result.add(family);
      family = families[family]?.parentId;
    }
    return result;
  }

  return [
    for (final group in groups.entries)
      for (final item in group.value)
        {
          'kind': group.key,
          'id': item.id as String,
          'label': _rowLabel(item),
          'familyId': metadata['${group.key}:${item.id as String}']?.familyId,
          'familyIds': lineage(
            metadata['${group.key}:${item.id as String}']?.familyId,
          ),
          'placementContext': metadata['${group.key}:${item.id as String}']
              ?.placementContext
              ?.name,
        },
  ]..sort((a, b) => _rowKey(a).compareTo(_rowKey(b)));
}

String _rowKey(Map<String, Object?> row) =>
    jsonEncode([row['kind'], row['id']]);
Set<String> _refs(Object value) {
  if (value is! List || value.length > 200) _fail('selection_patch_too_large');
  return {
    for (final raw in value)
      if (raw is Map)
        _refKey(Map<String, dynamic>.from(raw))
      else
        throw const FormatException('A reference must be an object.'),
  };
}

String _refKey(Map<String, dynamic> ref) {
  _keys(ref, const {'kind', 'id'});
  final kind = _string(ref, 'kind');
  final id = _string(ref, 'id', max: 512);
  if (kind != 'smartTilePattern' &&
      !ResourcePackKind.values.any((k) => k.name == kind)) {
    _fail('kind_invalid');
  }
  return jsonEncode([kind, id]);
}

ResourcePackRef _portableRef(String key) {
  final ref = jsonDecode(key) as List;
  return ResourcePackRef(
    kind: ResourcePackKind.values.singleWhere((k) => k.name == ref[0]),
    id: ref[1] as String,
  );
}

_Selection _selection(_TransferSession session, Map<String, dynamic> args) {
  final selected = session.selections[_string(args, 'selectionHandle')];
  if (selected == null) _fail('selection_unknown');
  if (selected.revision != _string(args, 'revision')) _fail('selection_stale');
  return selected;
}

Map<String, Object?> _selectionSummary(
  _TransferSession session,
  _Selection selection,
) => {
  'selectionHandle': selection.id,
  'revision': selection.revision,
  'mode': selection.mode,
  'sourceRevision': selection.sourceRevision,
  'selectedCount': selection.selected.length,
  'totalAvailable': selection.rows.length,
  'uri': _uri(session, 'resourcePackSelection', selection.id),
  'entriesUri': _uri(session, 'resourcePackEntry', selection.id),
};
Map<String, dynamic> _filter(Map<String, dynamic> args) {
  final filter = args['filter'] ?? const <String, dynamic>{};
  if (filter is! Map) _fail('filter_invalid');
  final result = Map<String, dynamic>.from(filter);
  _keys(result, const {'kind', 'search', 'selected', 'context', 'familyId'});
  if (result['kind'] != null &&
      !ResourcePackKind.values.any((kind) => kind.name == result['kind']) &&
      result['kind'] != 'smartTilePattern') {
    _fail('filter_invalid');
  }
  if (result['familyId'] != null) _string(result, 'familyId', max: 512);
  if (result['context'] != null &&
      !const {
        'all',
        'interior',
        'exterior',
        'both',
        'unspecified',
      }.contains(result['context'])) {
    _fail('filter_invalid');
  }
  if (result['search'] != null) _string(result, 'search', max: 256);
  if (result['selected'] != null && result['selected'] is! bool) {
    _fail('filter_invalid');
  }
  return result;
}

List<Map<String, Object?>> _filterRows(
  List<Map<String, Object?>> rows,
  Map<String, dynamic> filter,
  _Selection? selection,
) => [
  for (final row in rows)
    if ((filter['kind'] == null || filter['kind'] == row['kind']) &&
        (filter['search'] == null ||
            ('${row['label']} ${row['id']}').toLowerCase().contains(
              (filter['search'] as String).toLowerCase(),
            )) &&
        _matchesContext(row['placementContext'], filter['context']) &&
        (filter['familyId'] == null ||
            (filter['familyId'] == '__unclassified__'
                ? row['familyId'] == null
                : (row['familyIds'] as List).contains(filter['familyId']))) &&
        (filter['selected'] == null ||
            selection?.selected.contains(_rowKey(row)) == filter['selected']))
      {
        ...row,
        if (selection != null)
          'selected': selection.selected.contains(_rowKey(row)),
      },
];
Map<String, Object?> _page(
  _TransferSession session,
  String owner,
  String revision,
  List<Map<String, Object?>> rows,
  Map<String, dynamic> args,
  String kind,
) {
  final limit = _integer(args, 'limit', fallback: 50);
  if (limit < 1 || limit > 200) _fail('page_limit_invalid');
  final filterKey = canonicalAuthoringJson({'section': args['section'] ?? 'resources', 'filter': args['filter'] ?? const {}});
  var offset = 0;
  if (args['cursor'] != null) {
    final cursor = session.cursors[args['cursor']];
    if (cursor == null ||
        cursor.$1 != owner ||
        cursor.$2 != revision ||
        cursor.$3 != filterKey) {
      _fail('cursor_invalid');
    }
    offset = cursor.$4;
  }
  final items = <Map<String, Object?>>[];
  var bytes = 8192;
  for (
    var index = offset;
    index < rows.length && items.length < limit;
    index++
  ) {
    final item = {...rows[index]};
    final encoded = jsonEncode(item);
    final length = utf8.encode(encoded).length + utf8.encode(jsonEncode(encoded)).length + 512;
    if (length > 200 * 1024) _fail('row_too_large');
    if (bytes + length > 110 * 1024) break;
    items.add(item);
    bytes += length;
  }
  if (items.isEmpty && offset < rows.length) _fail('row_too_large');
  final end = offset + items.length;
  final cursor = end < rows.length ? _token('page') : null;
  if (cursor != null) {
    session.cursors[cursor] = (owner, revision, filterKey, end);
  }
  return {
    'items': items,
    'returned': items.length,
    'totalAvailable': rows.length,
    'revision': revision,
    'snapshotRevision': session.revision,
    if (cursor != null) 'nextCursor': cursor,
  };
}

Map<String, Object?> _queryPage(Map<String, Object?> page) => {
  'snapshotRevision': page['snapshotRevision'],
  'items': page['items'],
  'returned': page['returned'],
  'totalAvailable': page['totalAvailable'],
  if (page['nextCursor'] != null) 'nextCursor': page['nextCursor'],
};

bool _matchesContext(Object? value, Object? context) => switch (context) {
  null || 'all' => true,
  'interior' => value == 'interior' || value == 'both',
  'exterior' => value == 'exterior' || value == 'both',
  'unspecified' => value == null,
  'both' => value == 'both',
  _ => false,
};

String _rowLabel(dynamic item) => item is BorderBlueprintRecord
    ? item.draft.definition.name
    : item.name as String;

final class _ExportArtifact {
  const _ExportArtifact(this.owner, this.payloadRef);
  final OwnedResourcePackExport owner;
  final String payloadRef;
}
