part of 'resource_pack_transfer_controller.dart';

extension _ResourcePackRelease on ResourcePackTransferController {
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
    budgetReports = const [];
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
    budgetReports = const [];
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
}
