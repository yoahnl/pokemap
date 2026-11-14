part of 'resource_pack_transfer_controller.dart';

extension _ResourcePackJob on ResourcePackTransferController {
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
          _takeBudgetReports(completed);
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
          final details = result['result'];
          if (details is Map) {
            _takeBudgetReports(Map<String, Object?>.from(details));
          }
          throw ResourceFailure(
            budgetReports.isNotEmpty && snapshot['errorMessage'] is String
                ? snapshot['errorMessage']! as String
                : 'Le pack a été refusé (${snapshot['errorCode'] ?? 'erreur de transfert'}).',
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

  Future<bool> _retryReconciliation() async {
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

  Future<void> _recover() async {
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
