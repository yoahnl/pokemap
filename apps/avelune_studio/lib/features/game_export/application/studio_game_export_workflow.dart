import 'package:flutter/foundation.dart';

import '../domain/studio_game_export_port.dart';
import 'game_export_slug.dart';

class StudioGameExportWorkflow extends ChangeNotifier {
  StudioGameExportWorkflow({
    required this.controller,
    required this.pickFile,
    required this.prepare,
    required this.hasPendingChanges,
    required this.isCurrentProject,
    required this.isActive,
    this.preparationFailure,
    this.onPublished,
  });

  final StudioGameExportPort controller;
  final PickGameExportFile pickFile;
  final Future<bool> Function() prepare;
  final bool Function() hasPendingChanges, isCurrentProject, isActive;
  final String? Function()? preparationFailure;
  final Future<void> Function()? onPublished;
  StudioGameExportDestination? destination;
  bool selectingDestination = false;
  String? inputError;
  bool _running = false, _disposed = false;

  bool get active => !_disposed && isActive();
  bool get canStart =>
      active && !_running && !selectingDestination && controller.canStart;

  Future<StudioGameExportDestination?> chooseDestination(
    StudioGameExportMetadata metadata,
  ) {
    if (!active ||
        _running ||
        selectingDestination ||
        controller.operationActive) {
      return Future.value();
    }
    return _pickDestination(metadata);
  }

  Future<StudioGameExportDestination?> _pickDestination(
    StudioGameExportMetadata metadata,
  ) async {
    selectingDestination = true;
    inputError = null;
    notifyListeners();
    try {
      final result = await pickFile(
        '${gameExportSlug(metadata.title)}-${metadata.version}.avelunegame',
      );
      if (!active || !isCurrentProject()) return null;
      destination = result;
      return result;
    } on Object catch (failure) {
      if (active) inputError = 'Sélection du fichier impossible : $failure';
      return null;
    } finally {
      selectingDestination = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> run({
    required StudioGameExportMetadata metadata,
    required Future<bool> Function(StudioGameExportDestination)
    confirmOverwrite,
    bool publication = true,
  }) async {
    if (!canStart || !isCurrentProject()) return false;
    _running = true;
    inputError = null;
    notifyListeners();
    try {
      final selected = destination ?? await _pickDestination(metadata);
      if (selected == null || !active || !isCurrentProject()) return false;
      if (selected.exists && !await confirmOverwrite(selected)) return false;
      if (!active || !isCurrentProject()) return false;
      final result = await controller.export(
        metadata: metadata,
        outputPath: selected.path,
        overwriteConfirmed: selected.exists,
        publication: publication,
        prepare: prepare,
        preparationFailure: preparationFailure,
        hasPendingChanges: hasPendingChanges,
        isCurrentProject: () => active && isCurrentProject(),
      );
      if (result && active && controller.outputPath == selected.path) {
        destination = StudioGameExportDestination(selected.path, exists: true);
        await onPublished?.call();
      }
      return result;
    } finally {
      _running = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
