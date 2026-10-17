import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:map_authoring/map_authoring_api.dart';

import '../domain/resource_pack_port.dart';
import '../domain/resource_port.dart';

enum ResourcePackTransferPhase {
  idle,
  picking,
  inspecting,
  selecting,
  preparing,
  preview,
  applying,
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
    this.pollInterval = const Duration(milliseconds: 80),
  });
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
  bool get blocksClose =>
      requiresReconciliation ||
      requiresRecovery ||
      (operationActive && !cancelAllowed);
  bool get canPrepare =>
      !operationActive &&
      selectedCount > 0 &&
      phase == ResourcePackTransferPhase.selecting;
  bool get canApply =>
      !operationActive &&
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
  Future<void> _run(Future<void> Function(int epoch) work) {
    if (_disposed || operationActive || blocksClose || _closing) {
      return Future.value();
    }
    final epoch = _epoch;
    operationActive = true;
    error = null;
    cancelAllowed = true;
    jobPhase = null;
    jobCounters = const {};
    _changed();
    final operation = () async {
      try {
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
    _summary(summary);
    await _loadPage();
  });
  Future<void> prepare({bool importCopy = false}) => _run((epoch) async {
    if (_selection == null || selectedCount == 0) return;
    await _releasePreparation();
    phase = ResourcePackTransferPhase.preparing;
    _changed();
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
    final result = await port.transfer('preview', {
      'previewHandle': _previewHandle,
      'limit': 100,
      'cursor': ?cursor,
    });
    if (_disposed) return;
    preview = _rows(result['items']);
    previewCursor = result['nextCursor'] as String?;
    _changed();
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
          for (final key in [
            'archiveHandle',
            'inspectionHandle',
            'preparedImportHandle',
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
    } finally {
      _closing = false;
    }
  }

  Future<void> _release() async {
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
    for (final handle in [_prepared, _previewHandle].nonNulls) {
      await port.transfer('release', {'handle': handle});
      _handles.remove(handle);
    }
    _prepared = null;
    _previewHandle = null;
    preview = const [];
    previewCursor = null;
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
