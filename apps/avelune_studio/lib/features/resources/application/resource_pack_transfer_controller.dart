import 'dart:async';
import 'dart:convert';

import 'package:map_core/map_core.dart' show ResourcePackMetadata;

import 'package:flutter/foundation.dart';
import 'package:map_authoring/map_authoring_api.dart';

import '../domain/resource_pack_port.dart';
import '../domain/resource_port.dart';

enum ResourcePackTransferDirection { importing, exporting }

enum ResourcePackTransferPhase {
  idle,
  picking,
  inspecting,
  selecting,
  preparing,
  preview,
  applying,
  building,
  writing,
  publishing,
  publicationRequired,
  complete,
  reconciliationRequired,
  recoveryRequired,
  closed,
}

final class ResourcePackTransferController extends ChangeNotifier {
  ResourcePackTransferController({
    required this.port,
    required this.picker,
    required this.accept,
    this.pickLicenses,
    this.exportSink,
    this.localDrafts,
    this.pollInterval = const Duration(milliseconds: 80),
  });
  final PickResourcePackLicenses? pickLicenses;
  final ResourcePackExportSink? exportSink;
  final List<ResourcePackLocalDraft> Function()? localDrafts;
  ResourcePackTransferDirection direction =
      ResourcePackTransferDirection.importing;
  bool get exporting => direction == ResourcePackTransferDirection.exporting;
  bool get exportAvailable => exportSink != null;
  Map<String, String> exportFields = const {};
  List<ResourcePackLicenseDocument> licenseDocuments = const [];
  List<ResourcePackLocalDraft> localNotices = const [];
  bool requiresOrganizationAcknowledgement = false,
      organizationAcknowledged = false;
  String? outputPath;
  String _exportId = "";
  int _inputRevision = 0, _releasingInputs = 0;
  Future<void> _inputCleanup = Future.value();
  String? _artifactHandle;
  String? _pendingPublicationToken;
  final _nativePreviewOwners = <String, String>{};
  Future<void> _nativeOwnerCleanup = Future.value();
  final ResourcePackPort port;
  final PickResourcePack picker;
  final Future<void> Function(ResourceMutationReceipt receipt) accept;
  final Duration pollInterval;
  ResourcePackTransferPhase phase = ResourcePackTransferPhase.idle;
  String? error, notice, jobPhase;
  String context = 'all', search = '';
  String? kind;
  String? familyId, selectedFamilyLabel;
  List<Map<String, Object?>> families = const [], attributions = const [];
  String? familyCursor, attributionCursor;
  String attributionSection = 'authors';
  int familyCount = 0, attributionCount = 0;
  Map<String, Object?> inspection = const {}, preparedSummary = const {};
  Map<String, int> jobCounters = const {};
  List<Map<String, Object?>> entries = const [], preview = const [];
  int selectedCount = 0,
      visibleCount = 0,
      totalCount = 0,
      resourceCount = 0,
      conflictCount = 0;
  String? nextCursor, previewCursor;
  bool operationActive = false, cancelAllowed = true, routeActive = false;
  bool _disposed = false, _closing = false;
  int _epoch = 0, _pageEpoch = 0;
  String? _selection,
      _selectionRevision,
      _prepared,
      _previewHandle,
      _expectedRevision,
      _jobId,
      _operationId;
  final _handles = <String>{};
  ResourceMutationReceipt? _receipt;
  ({String kind, String id})? firstImported;
  int addedCount = 0;
  ResourceMutationReceipt? get pendingReceipt => _receipt;
  Future<void>? _operation;
  Future<bool>? _closeFuture;
  bool get requiresReconciliation =>
      phase == ResourcePackTransferPhase.reconciliationRequired;
  bool get requiresRecovery =>
      phase == ResourcePackTransferPhase.recoveryRequired;
  bool get requiresPublicationReconciliation =>
      _pendingPublicationToken != null;
  bool get blocksClose =>
      requiresPublicationReconciliation ||
      requiresReconciliation ||
      requiresRecovery ||
      (operationActive && !cancelAllowed);
  bool get canPrepare =>
      !operationActive &&
      selectedCount > 0 &&
      phase == ResourcePackTransferPhase.selecting &&
      _releasingInputs == 0 &&
      (!exporting || exportValidation == null);
  bool get canApply =>
      !operationActive &&
      !exporting &&
      phase == ResourcePackTransferPhase.preview &&
      _prepared != null &&
      conflictCount == 0;
  Map<String, Object?> get filter => {
    'context': context,
    if (kind != null) 'kind': kind,
    if (familyId != null) 'familyId': familyId,
    if (search.trim().isNotEmpty) 'search': search.trim(),
  };

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  bool _current(int epoch) => !_disposed && epoch == _epoch;
  Future<void> _run(
    Future<void> Function(int epoch) work, {
    bool publicationRetry = false,
  }) {
    if (_disposed ||
        operationActive ||
        (blocksClose &&
            !(publicationRetry && requiresPublicationReconciliation)) ||
        _closing) {
      return Future.value();
    }
    final epoch = _epoch;
    operationActive = true;
    error = null;
    cancelAllowed = !publicationRetry;
    jobPhase = null;
    jobCounters = const {};
    _changed();
    final operation = () async {
      try {
        await _inputCleanup;
        if (!_current(epoch)) return;
        await work(epoch);
      } on _PackCancelled {
        if (_current(epoch)) phase = ResourcePackTransferPhase.closed;
      } on _PackRecovery {
        if (_current(epoch)) {
          phase = ResourcePackTransferPhase.recoveryRequired;
          notice = 'La finalisation nécessite une reprise du projet.';
        }
      } on Object catch (failure) {
        if (_current(epoch)) {
          error = '$failure';
          if (requiresPublicationReconciliation) {
            phase = ResourcePackTransferPhase.publicationRequired;
            notice = 'Le résultat de publication doit être relu avant de fermer le projet.';
            return;
          }
          if (failure is ResourceFailure && failure.partialReceipt != null) {
            _receipt = failure.partialReceipt;
          }
          if (failure is ResourcePackCommittedFailure || _receipt != null) {
            phase = ResourcePackTransferPhase.reconciliationRequired;
            notice = 'Import terminé — relire la bibliothèque';
          } else {
            phase = _selection == null
                ? ResourcePackTransferPhase.idle
                : ResourcePackTransferPhase.selecting;
          }
        }
      } finally {
        if (_current(epoch)) {
          operationActive = false;
          _jobId = null;
          _changed();
        }
      }
    }();
    _operation = operation;
    return operation;
  }

  Future<void> beginImport() => _run((epoch) async {
    await _release();
    direction = ResourcePackTransferDirection.importing;
    outputPath = null;
    context = 'all';
    kind = null;
    familyId = null;
    selectedFamilyLabel = null;
    families = const [];
    attributions = const [];
    inspection = const {};
    preparedSummary = const {};
    search = '';
    selectedCount = 0;
    addedCount = 0;
    firstImported = null;
    familyCursor = null;
    attributionCursor = null;
    familyCount = 0;
    attributionCount = 0;
    entries = const [];
    preview = const [];
    notice = null;
    _receipt = null;
    _prepared = null;
    phase = ResourcePackTransferPhase.picking;
    _changed();
    final path = await picker();
    if (!_current(epoch)) return;
    if (_closing || path == null) {
      phase = ResourcePackTransferPhase.closed;
      return;
    }
    await port.authorizeSource(path);
    if (!_current(epoch) || _closing) return;
    phase = ResourcePackTransferPhase.inspecting;
    _changed();
    final staged = await _monitor(
      await port.transfer('stage', {'sourcePath': path}),
    );
    final archive = staged['archiveHandle']! as String;
    _handles.add(archive);
    final inspected = await _monitor(
      await port.transfer('inspect', {'archiveHandle': archive}),
    );
    inspection = Map.unmodifiable(inspected);
    final inspectionHandle = inspected['inspectionHandle']! as String;
    _handles.add(inspectionHandle);
    final summary = await port.transfer('selection.create', {
      'mode': 'archive',
      'inspectionHandle': inspectionHandle,
    });
    if (!_current(epoch) || _closing) return;
    _selection = summary['selectionHandle']! as String;
    _handles.add(_selection!);
    _summary(summary);
    phase = ResourcePackTransferPhase.selecting;
    await _loadFamilies();
    await _loadAttributions();
    await _loadPage();
  });

  String? get exportValidation {
    try {
      _exportMetadata();
      final url = exportFields['sourceUrl']?.trim() ?? '';
      if (url.isNotEmpty) {
        final uri = Uri.tryParse(url);
        if (uri == null ||
            !const ['http', 'https'].contains(uri.scheme) ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty) {
          return 'Utilisez une URL HTTP ou HTTPS sans identifiants.';
        }
      }
      return null;
    } on Object {
      return 'Renseignez le nom, une version comme 1.0.0, l’auteur (128 caractères maximum), l’univers et la provenance.';
    }
  }

  Map<String, Object?> _exportMetadata() => ResourcePackMetadata(
    id: _exportId,
    version: exportFields['version'] ?? '',
    name: exportFields['name'] ?? '',
    description: exportFields['description'] ?? '',
    universeId: exportFields['universeId'] ?? '',
    authors: [exportFields['author'] ?? ''],
    provenance: exportFields['provenance'] ?? '',
  ).toJson();
  bool get canExport =>
      exporting &&
      exportAvailable &&
      !operationActive &&
      _releasingInputs == 0 &&
      phase == ResourcePackTransferPhase.preview &&
      _prepared != null &&
      (!requiresOrganizationAcknowledgement || organizationAcknowledged);
  Future<void> beginExport({String projectName = ''}) => _run((epoch) async {
    if (!exportAvailable) return;
    await _release();
    direction = ResourcePackTransferDirection.exporting;
    context = 'all';
    kind = null;
    familyId = null;
    selectedFamilyLabel = null;
    search = '';
    selectedCount = 0;
    addedCount = 0;
    firstImported = null;
    entries = const [];
    preview = const [];
    families = const [];
    attributions = const [];
    inspection = const {};
    preparedSummary = const {};
    notice = null;
    outputPath = null;
    _receipt = null;
    _exportId = 'studio-pack-${DateTime.now().microsecondsSinceEpoch}';
    exportFields = Map.unmodifiable({
      'name': projectName,
      'version': '1.0.0',
      'author': '',
      'description': '',
      'universeId': '',
      'provenance': '',
      'sourceUrl': '',
    });
    final summary = await port.transfer('selection.create', {'mode': 'native'});
    final handle = summary['selectionHandle']! as String;
    _handles.add(handle);
    if (!_current(epoch) || _closing) return;
    _selection = handle;
    _expectedRevision = summary['sourceRevision']! as String;
    _summary(summary);
    phase = ResourcePackTransferPhase.selecting;
    await _loadFamilies();
    await _loadAttributions();
    await _loadPage();
  });
  Future<void> setExportField(String field, String value) async {
    if (!exporting ||
        _disposed ||
        operationActive ||
        requiresPublicationReconciliation ||
        _closing ||
        !const [
          'name',
          'version',
          'author',
          'description',
          'universeId',
          'provenance',
          'sourceUrl',
        ].contains(field)) {
      return;
    }
    exportFields = Map.unmodifiable({...exportFields, field: value});
    _inputRevision++;
    organizationAcknowledged = false;
    if (phase == ResourcePackTransferPhase.complete) outputPath = null;
    phase = ResourcePackTransferPhase.selecting;
    final epoch = _epoch;
    _releasingInputs++;
    final cleanup = _releasePreparation();
    _inputCleanup = Future.wait([_inputCleanup, cleanup]).then<void>(
      (_) {},
      onError: (Object failure, StackTrace stack) {
        if (_current(epoch) && !_closing) {
          error = '$failure';
          _changed();
        }
      },
    );
    _changed();
    try {
      await cleanup;
    } on Object catch (failure) {
      if (_current(epoch) && !_closing) error = '$failure';
    } finally {
      _releasingInputs--;
      if (_current(epoch)) _changed();
    }
  }

  void setOrganizationAcknowledgement(bool value) {
    if (!exporting ||
        operationActive ||
        phase != ResourcePackTransferPhase.preview) {
      return;
    }
    organizationAcknowledged = value;
    _changed();
  }

  Future<void> addLicenseDocuments() => _run((epoch) async {
    if (!exporting || pickLicenses == null) return;
    final paths = await pickLicenses!();
    if (!_current(epoch) || _closing || paths == null || paths.isEmpty) return;
    if (paths.length + licenseDocuments.length > 200) {
      throw const ResourceFailure(
        'Choisissez au maximum 200 documents de licence.',
      );
    }
    await _releasePreparation();
    phase = ResourcePackTransferPhase.selecting;
    for (final path in paths) {
      await port.authorizeSource(path);
      if (!_current(epoch) || _closing) return;
      final staged = await _monitor(
        await port.transfer('stage_license', {'sourcePath': path}),
      );
      final handle = staged['licenseHandle']! as String;
      if (licenseDocuments.any((d) => d.rawSha256 == staged['rawSha256'])) {
        await port.transfer('release', {'handle': handle});
        _handles.remove(handle);
        continue;
      }
      licenseDocuments = List.unmodifiable([
        ...licenseDocuments,
        ResourcePackLicenseDocument(
          handle: handle,
          label: path.split(RegExp(r'[/\\]')).last,
          rawSha256: staged['rawSha256']! as String,
          byteLength: staged['byteLength']! as int,
        ),
      ]);
    }
    _inputRevision++;
    organizationAcknowledged = false;
  });
  Future<void> removeLicenseDocument(String handle) => _run((_) async {
    if (!exporting) return;
    await _releasePreparation();
    await port.transfer('release', {'handle': handle});
    _handles.remove(handle);
    licenseDocuments = List.unmodifiable(
      licenseDocuments.where((d) => d.handle != handle),
    );
    _inputRevision++;
    phase = ResourcePackTransferPhase.selecting;
  });
  Future<List<ResourcePackLocalDraft>> _reachedLocalDrafts(
    int epoch,
    String handle,
  ) async {
    final candidates = {
      for (final draft
          in localDrafts?.call() ?? const <ResourcePackLocalDraft>[])
        '${draft.kind}:${draft.id}': draft,
    };
    final found = <String, ResourcePackLocalDraft>{};
    if (candidates.isEmpty) return const [];
    String? cursor;
    do {
      final page = await port.transfer('preview', {
        'previewHandle': handle,
        'limit': 200,
        'cursor': ?cursor,
      });
      if (!_current(epoch) || _closing || _previewHandle != handle) {
        return const [];
      }
      for (final row in _rows(page['items'])) {
        final key = '${row['resourceKind']}:${row['nativeId']}';
        final draft = candidates[key];
        if (draft != null) found[key] = draft;
      }
      final next = page['nextCursor'] as String?;
      if (next != null && next == cursor) {
        throw const ResourceFailure('L’aperçu ne progresse plus.');
      }
      cursor = next;
    } while (cursor != null);
    final keys = found.keys.toList()..sort();
    return List.unmodifiable(keys.map((key) => found[key]!));
  }

  String _localSignature(List<ResourcePackLocalDraft> drafts) => jsonEncode(
    drafts.map((d) => [d.kind, d.id, d.signature, d.saving]).toList(),
  );
  Future<void> export() {
    if (!canExport) return Future.value();
    return _run((epoch) async {
      final handle = _previewHandle!, prepared = _prepared!;
      final current = await _reachedLocalDrafts(epoch, handle);
      if (!_current(epoch) || _closing) return;
      if (_localSignature(current) != _localSignature(localNotices)) {
        localNotices = current;
        organizationAcknowledged = false;
        notice = 'Vos modifications en cours ont changé. Relisez les versions publiées avant de poursuivre.';
        return;
      }
      phase = ResourcePackTransferPhase.building;
      _changed();
      final artifact = await _monitor(
        await port.transfer('export', {
          'preparedExportHandle': prepared,
          'acknowledgeOrganizationRemoval': organizationAcknowledged,
        }),
      );
      _artifactHandle = artifact['artifactHandle']! as String;
      if (!_current(epoch) || _closing) return;
      phase = ResourcePackTransferPhase.writing;
      cancelAllowed = true;
      _changed();
      var published = false;
      try {
        final result = await exportSink!.publish(
          suggestedName: '${exportFields['name']}.aveluneassets',
          byteLength: artifact['byteLength']! as int,
          rawSha256: artifact['rawSha256']! as String,
          readChunk: (offset, length) => port.readExportPayloadChunk(
            artifact['payloadRef']! as String,
            offset,
            length,
          ),
          isCancelled: () => _closing || !_current(epoch),
          enterFinalization: () {
            if (_closing || !_current(epoch)) throw const _PackCancelled();
            cancelAllowed = false;
            phase = ResourcePackTransferPhase.publishing;
            _changed();
          },
        );
        published = result.published;
        _acceptPublication(result);
      } finally {
        try {
          await _releaseArtifact();
        } on Object catch (failure) {
          if (published) {
            notice = '$notice · Nettoyage à reprendre : $failure';
          } else {
            rethrow;
          }
        }
      }
    });
  }

  void _acceptPublication(ResourcePackPublication result) {
    _pendingPublicationToken = result.pendingToken;
    if (result.pendingToken != null) {
      phase = ResourcePackTransferPhase.publicationRequired;
      cancelAllowed = false;
      notice = result.warning ?? 'Le résultat de publication doit être relu avant de fermer le projet.';
      return;
    }
    if (result.published) {
      outputPath = result.path;
      phase = ResourcePackTransferPhase.complete;
      notice =
          'Pack exporté : ${result.path}${result.warning == null ? '' : ' · ${result.warning}'}';
    } else {
      phase = ResourcePackTransferPhase.preview;
      notice = result.warning ?? 'Export annulé. Aucun fichier n’a été publié.';
    }
  }

  Future<void> retryPublication() => _run((_) async {
    final token = _pendingPublicationToken;
    if (token == null) return;
    _acceptPublication(await exportSink!.reconcilePublication(token));
  }, publicationRetry: true);
  Future<void> _releaseArtifact() async {
    final handle = _artifactHandle;
    if (handle == null) return;
    await port.transfer('release', {'handle': handle});
    _handles.remove(handle);
    _artifactHandle = null;
  }

  void _summary(Map<String, Object?> value) {
    _selectionRevision = value['revision']! as String;
    selectedCount = value['selectedCount']! as int;
    totalCount = value['totalAvailable']! as int;
    nextCursor = null;
    _pageEpoch++;
  }

  Future<void> setFilter({
    String? context,
    String? kind,
    String? search,
    String? familyId,
  }) async {
    if (operationActive ||
        phase != ResourcePackTransferPhase.selecting ||
        _disposed) {
      return;
    }
    if (context != null) this.context = context;
    if (kind != null) this.kind = kind.isEmpty ? null : kind;
    if (search != null) this.search = search;
    if (familyId != null) {
      this.familyId = familyId.isEmpty ? null : familyId;
      selectedFamilyLabel =
          families.where((row) => row['id'] == familyId).firstOrNull?['label']
              as String?;
    }
    await _loadPage();
  }

  Future<void> _loadPage({String? cursor}) async {
    final selection = _selection;
    if (selection == null) return;
    final epoch = _epoch, page = ++_pageEpoch;
    try {
      final result = await port.query(
        AuthoringQueryRequest(
          operation: AuthoringQueryOperation.get,
          resourceKind: 'resourcePackEntry',
          ids: [selection],
          filters: filter,
          cursor: cursor,
          pageSize: 100,
        ),
      );
      if (!_current(epoch) || page != _pageEpoch || _closing) return;
      entries = _rows(result['items']);
      visibleCount = result['totalAvailable']! as int;
      nextCursor = result['nextCursor'] as String?;
      _changed();
    } on Object catch (failure) {
      if (_current(epoch) && page == _pageEpoch && !_closing) {
        error = '$failure';
        _changed();
      }
    }
  }

  Future<void> nextPage() => _run((_) async => _loadPage(cursor: nextCursor));
  Future<void> firstPage() => _run((_) async => _loadPage());
  Future<void> _loadFamilies({String? cursor}) async {
    final epoch = _epoch;
    final result = await port.transfer('entries', {
      'selectionHandle': _selection,
      'section': 'families',
      'limit': 50,
      'cursor': ?cursor,
    });
    if (!_current(epoch) || _closing) return;
    families = _rows(result['items']);
    familyCount = result['totalAvailable']! as int;
    familyCursor = result['nextCursor'] as String?;
    _changed();
  }

  Future<void> nextFamilyPage() =>
      _run((_) => _loadFamilies(cursor: familyCursor));
  Future<void> firstFamilyPage() => _run((_) => _loadFamilies());
  Future<void> _loadAttributions({String? cursor}) async {
    final epoch = _epoch;
    final result = await port.transfer('entries', {
      'selectionHandle': _selection,
      'section': attributionSection,
      'limit': 20,
      'cursor': ?cursor,
    });
    if (!_current(epoch) || _closing) return;
    attributions = _rows(result['items']);
    attributionCount = result['totalAvailable']! as int;
    attributionCursor = result['nextCursor'] as String?;
    _changed();
  }

  Future<void> showAttributions(String section) => _run((_) async {
    attributionSection = section;
    await _loadAttributions();
  });
  Future<void> nextAttributionPage() =>
      _run((_) => _loadAttributions(cursor: attributionCursor));
  Future<void> selectFiltered() => _run((epoch) async {
    final summary = await port.transfer('selection.select_filtered', {
      'selectionHandle': _selection,
      'revision': _selectionRevision,
      'filter': filter,
    });
    if (!_current(epoch)) return;
    if (exporting) await _releasePreparation();
    _summary(summary);
    await _loadPage();
  });
  Future<void> toggle(Map<String, Object?> entry) => _run((epoch) async {
    final summary = await port.transfer('selection.patch', {
      'selectionHandle': _selection,
      'revision': _selectionRevision,
      entry['selected'] == true ? 'remove' : 'add': [
        {'kind': entry['kind'], 'id': entry['id']},
      ],
    });
    if (!_current(epoch)) return;
    if (exporting) await _releasePreparation();
    _summary(summary);
    await _loadPage();
  });
  Future<void> prepare({bool importCopy = false}) => _run((epoch) async {
    if (_selection == null || selectedCount == 0) return;
    await _releasePreparation();
    phase = ResourcePackTransferPhase.preparing;
    _changed();
    if (exporting) {
      if (exportValidation != null) throw ResourceFailure(exportValidation!);
      final prepared = await _monitor(
        await port.transfer('prepare', {
          'selectionHandle': _selection,
          'revision': _selectionRevision,
          'expectedRevision': _expectedRevision,
          'metadata': _exportMetadata(),
          'author': exportFields['author'],
          if ((exportFields['sourceUrl'] ?? '').trim().isNotEmpty)
            'sourceUrl': exportFields['sourceUrl']!.trim(),
          'licenseHandles': licenseDocuments.map((d) => d.handle).toList(),
        }),
      );
      if (!_current(epoch) || _closing) return;
      _prepared = prepared['preparedExportHandle']! as String;
      _previewHandle = prepared['previewHandle']! as String;
      preparedSummary = Map.unmodifiable(
        Map<String, Object?>.from(prepared['summary']! as Map),
      );
      resourceCount = prepared['resourceCount']! as int;
      conflictCount = 0;
      requiresOrganizationAcknowledgement =
          prepared['requiresOrganizationAcknowledgement']! as bool;
      organizationAcknowledged = false;
      localNotices = await _reachedLocalDrafts(epoch, _previewHandle!);
      await _loadPreview();
      if (_current(epoch) && !_closing) {
        phase = ResourcePackTransferPhase.preview;
      }
      return;
    }
    _expectedRevision = await port.captureRevision();
    final prepared = await _monitor(
      await port.transfer('prepare', {
        'selectionHandle': _selection,
        'revision': _selectionRevision,
        'expectedRevision': _expectedRevision,
        'conflictPolicy': importCopy ? 'importCopy' : 'preserveProject',
      }),
    );
    if (!_current(epoch)) return;
    _prepared = prepared['preparedImportHandle'] as String?;
    if (_prepared != null) _handles.add(_prepared!);
    _previewHandle = prepared['previewHandle'] as String?;
    resourceCount = prepared['resourceCount']! as int;
    conflictCount = prepared['conflictCount']! as int;
    preparedSummary = Map.unmodifiable(
      Map<String, Object?>.from(prepared['summary']! as Map),
    );
    if (_previewHandle != null) await _loadPreview();
    phase = prepared['status'] == 'alreadyInstalled'
        ? ResourcePackTransferPhase.complete
        : ResourcePackTransferPhase.preview;
    if (prepared['status'] == 'alreadyInstalled') {
      notice =
          'Ces ressources sont déjà installées. ${preparedSummary['localModifiedResourceCount']} définitions modifiées et ${preparedSummary['localDeletedResourceCount']} suppressions locales conservées.';
    }
  });
  Future<void> _loadPreview({String? cursor}) async {
    final epoch = _epoch, handle = _previewHandle, input = _inputRevision;
    if (handle == null) return;
    try {
      final result = await port.transfer('preview', {
        'previewHandle': handle,
        'limit': 100,
        'cursor': ?cursor,
      });
      if (!_current(epoch) ||
          _closing ||
          _previewHandle != handle ||
          _inputRevision != input) {
        return;
      }
      preview = _rows(result['items']);
      previewCursor = result['nextCursor'] as String?;
      _changed();
    } on Object catch (failure) {
      if (_current(epoch) &&
          !_closing &&
          _previewHandle == handle &&
          _inputRevision == input) {
        error = '$failure';
        _changed();
      }
    }
  }

  Future<void> nextPreviewPage() =>
      _run((_) => _loadPreview(cursor: previewCursor));
  Future<void> backToSelection() => _run((_) async {
    await _releasePreparation();
    phase = ResourcePackTransferPhase.selecting;
    _changed();
  });

  Future<void> apply() {
    if (!canApply) return Future.value();
    return _run((epoch) async {
      if (_prepared == null) return;
      phase = ResourcePackTransferPhase.applying;
      _changed();
      _operationId = 'studio_pack_${DateTime.now().microsecondsSinceEpoch}';
      final receipt = await port.applyImport(
        preparedHandle: _prepared!,
        expectedRevision: _expectedRevision!,
        operationId: _operationId!,
        monitor: _monitor,
      );
      _receipt = receipt;
      _rememberImported();
      if (!_current(epoch)) return;
      await accept(receipt);
      phase = ResourcePackTransferPhase.complete;
      notice = _completionNotice;
      _receipt = null;
    });
  }

  Future<Map<String, Object?>> _monitor(Map<String, Object?> value) async {
    var result = value;
    var sequence = 0;
    while (true) {
      final snapshot = Map<String, Object?>.from(result['snapshot']! as Map);
      _jobId = snapshot['jobId']! as String;
      jobPhase = result['phase'] as String?;
      cancelAllowed =
          result['cancelAllowed'] as bool? ?? (snapshot['state'] == 'queued');
      _changed();
      if (jobPhase == 'recoveryRequired') throw const _PackRecovery();
      switch (snapshot['state']) {
        case 'succeeded':
          _jobId = null;
          final completed = Map<String, Object?>.from(result['result']! as Map);
          if (completed['preparedExportHandle'] case final String prepared) {
            if (completed['previewHandle'] case final String preview) {
              _nativePreviewOwners[prepared] = preview;
            }
          }
          for (final key in [
            'archiveHandle',
            'inspectionHandle',
            'preparedImportHandle',
            'licenseHandle',
            'preparedExportHandle',
            'artifactHandle',
            'previewHandle',
          ]) {
            if (completed[key] case final String handle) {
              _handles.add(handle);
            }
          }
          if (_closing && phase != ResourcePackTransferPhase.applying) {
            throw const _PackCancelled();
          }
          return completed;
        case 'cancelled':
          throw const _PackCancelled();
        case 'failed':
          throw ResourceFailure(
            'Le pack a été refusé (${snapshot['errorCode'] ?? 'erreur de transfert'}).',
          );
      }
      if (_closing && cancelAllowed) {
        try {
          await port.transfer('cancel', {'jobId': _jobId});
        } on ResourcePackTransferException catch (failure) {
          if (failure.code != 'resource_pack.cancel_not_allowed') rethrow;
        }
      }
      final events = await port.transfer('events', {
        'jobId': _jobId,
        'afterSequence': sequence,
      });
      for (final row in _rows(events['events'])) {
        sequence = row['sequence']! as int;
        if (row['counters'] case final Map counters) {
          jobCounters = Map.unmodifiable({
            for (final entry in counters.entries)
              if (entry.key is String && entry.value is int)
                entry.key as String: entry.value as int,
          });
        }
      }
      await Future<void>.delayed(pollInterval);
      result = await port.transfer('get', {'jobId': _jobId});
    }
  }

  Future<bool> retryReconciliation() async {
    if (!requiresReconciliation || operationActive || _disposed) return false;
    operationActive = true;
    _changed();
    try {
      final receipt = _receipt ??= await port.rereadApplied();
      _rememberImported();
      await port.reconcile(receipt);
      await accept(receipt);
      _receipt = null;
      phase = ResourcePackTransferPhase.complete;
      notice = 'Import terminé · bibliothèque relue';
      error = null;
      return true;
    } on Object catch (failure) {
      error = '$failure';
      return false;
    } finally {
      operationActive = false;
      _changed();
    }
  }

  Future<void> recover() async {
    if (!requiresRecovery || operationActive || _disposed) return;
    operationActive = true;
    _changed();
    try {
      final status = await port.transfer('recovery_status');
      if (status['recoveryRequired'] == true) {
        await _monitor(
          await port.transfer('start_recovery', {'operationId': _operationId}),
        );
      }
      _receipt = await port.rereadApplied();
      _rememberImported();
      await port.reconcile(_receipt!);
      await accept(_receipt!);
      _receipt = null;
      phase = ResourcePackTransferPhase.complete;
      notice = 'Import terminé · reprise achevée';
      error = null;
    } on Object catch (failure) {
      error = '$failure';
    } finally {
      operationActive = false;
      _changed();
    }
  }

  Future<bool> requestClose() =>
      _closeFuture ??= _requestClose().whenComplete(() {
        _closeFuture = null;
      });
  Future<bool> _requestClose() async {
    if (_disposed) return true;
    if (blocksClose) return false;
    _closing = true;
    try {
      final job = _jobId;
      if (operationActive && job != null) {
        try {
          await port.transfer('cancel', {'jobId': job});
        } on ResourcePackTransferException catch (failure) {
          if (failure.code == 'resource_pack.cancel_not_allowed') return false;
          rethrow;
        }
      }
      await _operation;
      if (blocksClose) return false;
      await _release();
      _epoch++;
      phase = ResourcePackTransferPhase.closed;
      routeActive = false;
      _changed();
      return true;
    } on Object catch (failure) {
      if (!_disposed) {
        error = '$failure';
        _changed();
      }
      return false;
    } finally {
      _closing = false;
    }
  }

  Future<void> _release() async {
    await _inputCleanup;
    if (exporting) {
      await _releasePreparation();
      for (final owner in _nativePreviewOwners.keys.toList()) {
        await _releaseNativeOwner(owner);
      }
    }
    licenseDocuments = const [];
    localNotices = const [];
    for (final handle in _handles.toList().reversed) {
      await port.transfer('release', {'handle': handle});
      _handles.remove(handle);
    }
    _selection = null;
    _selectionRevision = null;
    _prepared = null;
    _previewHandle = null;
  }

  Future<void> _releasePreparation() async {
    final prepared = _prepared, previewHandle = _previewHandle;
    _prepared = null;
    _previewHandle = null;
    preview = const [];
    previewCursor = null;
    preparedSummary = const {};
    localNotices = const [];
    organizationAcknowledged = false;
    requiresOrganizationAcknowledgement = false;
    if (exporting) {
      await _releaseArtifact();
      if (prepared != null) {
        await _releaseNativeOwner(prepared);
      } else if (previewHandle != null) {
        await port.transfer('release', {'handle': previewHandle});
        _handles.remove(previewHandle);
      }
      for (final owner in _nativePreviewOwners.keys.toList()) {
        await _releaseNativeOwner(owner);
      }
    } else {
      for (final handle in [prepared, previewHandle].nonNulls) {
        await port.transfer('release', {'handle': handle});
        _handles.remove(handle);
      }
    }
  }

  Future<void> _releaseNativeOwner(String owner) {
    final release = _nativeOwnerCleanup.then((_) async {
      if (!_nativePreviewOwners.containsKey(owner)) return;
      await port.transfer('release', {'handle': owner});
      _handles.remove(owner);
      final preview = _nativePreviewOwners.remove(owner);
      if (preview != null) _handles.remove(preview);
    });
    _nativeOwnerCleanup = release.then<void>(
      (_) {},
      onError: (Object failure, StackTrace stack) {},
    );
    return release;
  }

  String get _completionNotice =>
      'Import terminé · $addedCount ressources et supports ajoutés · ${preparedSummary['reusedDefinitionCount']} déjà installés. ${preparedSummary['localModifiedResourceCount']} définitions modifiées et ${preparedSummary['localDeletedResourceCount']} suppressions locales conservées.';
  void _rememberImported() {
    addedCount =
        (preparedSummary['createdDefinitionCount']! as int) +
        (preparedSummary['copiedDefinitionCount']! as int);
    final added = preparedSummary['firstAdded'];
    firstImported =
        added is Map && added['kind'] is String && added['id'] is String
        ? (kind: added['kind'] as String, id: added['id'] as String)
        : null;
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    unawaited(port.dispose());
    super.dispose();
  }
}

List<Map<String, Object?>> _rows(Object? value) => [
  for (final row in value as List? ?? const [])
    Map<String, Object?>.from(row as Map),
];

final class _PackCancelled implements Exception {
  const _PackCancelled();
}

final class _PackRecovery implements Exception {
  const _PackRecovery();
}
