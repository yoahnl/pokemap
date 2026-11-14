part of 'resource_pack_transfer_controller.dart';

extension _ResourcePackPreparation on ResourcePackTransferController {
  Future<void> _prepare({bool importCopy = false}) => _run((epoch) async {
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

  Future<void> _diagnose() => _run((epoch) async {
    if (_selection == null) return;
    final expected = exporting
        ? _expectedRevision
        : await port.captureRevision();
    final result = await _monitor(
      await port.transfer('diagnose', {
        'expectedRevision': expected,
        'selectionHandle': _selection,
        'revision': _selectionRevision,
      }),
    );
    if (!_current(epoch) || _closing) return;
    _takeBudgetReports(result);
    phase = ResourcePackTransferPhase.selecting;
  });

  void _takeBudgetReports(Map<String, Object?> value) {
    final list = value['budgetReports'];
    final summary = value['summary'];
    final single =
        value['budgetReport'] ??
        (summary is Map ? summary['budgetReport'] : null);
    if (list is List) {
      budgetReports = List.unmodifiable(
        list.whereType<Map>().map(
          (row) =>
              Map<String, Object?>.unmodifiable(Map<String, Object?>.from(row)),
        ),
      );
    } else if (single is Map) {
      budgetReports = [
        Map<String, Object?>.unmodifiable(Map<String, Object?>.from(single)),
      ];
    }
  }

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

  Future<void> _apply() {
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
}
