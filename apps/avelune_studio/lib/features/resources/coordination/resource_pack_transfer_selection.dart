part of 'resource_pack_transfer_controller.dart';

extension _ResourcePackSelection on ResourcePackTransferController {
  Future<void> _beginImport() => _run((epoch) async {
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

  void _summary(Map<String, Object?> value) {
    budgetReports = const [];
    _selectionRevision = value['revision']! as String;
    selectedCount = value['selectedCount']! as int;
    totalCount = value['totalAvailable']! as int;
    nextCursor = null;
    _pageEpoch++;
  }

  Future<void> _setFilter({
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

  Future<void> _selectFiltered() => _run((epoch) async {
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
  Future<void> _toggle(Map<String, Object?> entry) => _run((epoch) async {
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
}
