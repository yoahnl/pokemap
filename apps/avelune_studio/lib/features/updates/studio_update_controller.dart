import 'dart:async';

import 'package:flutter/foundation.dart';

import 'studio_update_catalog.dart';

class StudioUpdateController extends ChangeNotifier {
  StudioUpdateController({
    required this.nativeUpdater,
    required this.checkRelease,
    required this.openNativeUpdate,
    required this.respondToRestart,
    required this.openReleaseNotes,
    required this.prepareForRestart,
    required this.resumeAfterFailure,
    String Function()? createOperationId,
  }) : createOperationId =
           createOperationId ??
           (() => DateTime.now().microsecondsSinceEpoch.toString());

  final bool nativeUpdater;
  final Future<StudioUpdateRelease?> Function() checkRelease;
  final Future<void> Function(String operationId) openNativeUpdate;
  final Future<void> Function(String operationId, bool allowed)
  respondToRestart;
  final Future<bool> Function(Uri uri) openReleaseNotes;
  final Future<bool> Function() prepareForRestart;
  final Future<void> Function() resumeAfterFailure;
  final String Function() createOperationId;
  Timer? _checkTimer;
  StudioUpdateRelease? _release;
  String? _message;
  String? _operationId;
  bool _opening = false;
  bool _disposed = false;

  StudioUpdateRelease? get release => _release;
  String? get message => _message;
  String? get operationId => _operationId;
  bool get opening => _opening;

  void scheduleCheck() {
    if (_disposed || _checkTimer != null) return;
    _checkTimer = Timer(
      const Duration(seconds: 12),
      () => unawaited(checkForUpdates()),
    );
  }

  Future<void> checkForUpdates() async {
    if (_disposed) return;
    try {
      final release = await checkRelease();
      if (_disposed) return;
      _release = release;
      notifyListeners();
    } catch (error) {
      debugPrint('Studio update check failed: $error');
    }
  }

  Future<void> handleEvent(Map<Object?, Object?> event) async {
    if (_disposed ||
        _operationId == null ||
        event['operationId'] != _operationId) {
      return;
    }
    final operationId = _operationId!;
    if (event['kind'] == 'restartRequested') {
      var canRestart = false;
      try {
        canRestart = await prepareForRestart();
      } catch (error) {
        debugPrint('Studio update restart guard failed: $error');
      }
      if (_disposed) return;
      await respondToRestart(operationId, canRestart);
      if (!canRestart && !_disposed) {
        _message = 'Enregistrez le projet avant la mise à jour.';
        _opening = false;
        _operationId = null;
        notifyListeners();
      }
    } else if (event['kind'] == 'failed' ||
        event['kind'] == 'cancelled' ||
        event['kind'] == 'noUpdate') {
      await resumeAfterFailure();
      if (_disposed) return;
      _opening = false;
      _operationId = null;
      if (event['kind'] == 'failed') {
        _message = 'La mise à jour a échoué. Réessayez.';
      }
      notifyListeners();
    }
  }

  Future<void> openUpdate() async {
    final release = _release;
    if (_disposed || release == null || _opening) return;
    _opening = true;
    _message = null;
    notifyListeners();
    try {
      if (nativeUpdater) {
        _operationId = createOperationId();
        await openNativeUpdate(_operationId!);
      } else {
        final opened = await openReleaseNotes(release.notesUri);
        if (!opened) throw StateError('Unable to open release notes.');
      }
    } catch (error) {
      if (!_disposed) _message = 'Impossible d’ouvrir la mise à jour.';
      debugPrint('Studio update launch failed: $error');
    } finally {
      if (!_disposed && (!nativeUpdater || _message != null)) {
        _opening = false;
        _operationId = null;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _checkTimer?.cancel();
    super.dispose();
  }
}
