import 'package:flutter/foundation.dart';

import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_catalog.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/features/appearance/data/repositories/custom_background_repository_impl.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_read.dart';
import 'package:pokemap_hub/features/appearance/domain/repositories/avelune_appearance_repository_interface.dart';

enum AveluneAppearanceControllerStatus { idle, loading, ready, saving, error }

@immutable
final class AveluneAppearanceState {
  const AveluneAppearanceState({
    required this.status,
    required this.preferences,
    this.customBackgroundPath,
    this.customBackgroundThumbnailPath,
    this.message,
  });

  const AveluneAppearanceState.idle()
      : this(
          status: AveluneAppearanceControllerStatus.idle,
          preferences: const AveluneAppearancePreferences(),
        );

  final AveluneAppearanceControllerStatus status;
  final AveluneAppearancePreferences preferences;
  final String? customBackgroundPath;
  final String? customBackgroundThumbnailPath;
  final String? message;
}

/// Coordinates appearance persistence and custom-image import without owning
/// either file I/O implementation. Failures keep the last confirmed choice.
final class AveluneAppearanceController extends ChangeNotifier {
  AveluneAppearanceController({
    required this.store,
    required this.customBackground,
  });

  final AveluneAppearanceRepositoryInterface store;
  final AveluneCustomBackgroundGateway customBackground;
  AveluneAppearanceState _state = const AveluneAppearanceState.idle();

  AveluneAppearanceState get state => _state;

  Future<void> initialize() async {
    _emit(
      AveluneAppearanceState(
        status: AveluneAppearanceControllerStatus.loading,
        preferences: _state.preferences,
      ),
    );
    try {
      final read = await store.load();
      var preferences = read.preferences;
      String? message;
      var customIsValid = false;
      if (preferences.backgroundId ==
          AveluneAppearanceCatalog.customBackgroundId) {
        customIsValid = await customBackground.isCurrentValid();
        if (!customIsValid) {
          preferences = preferences.copyWith(
            backgroundId: AveluneAppearanceCatalog.defaultBackgroundId,
          );
          message =
              'L’image personnalisée est introuvable. Le fond Ambre a été restauré.';
          try {
            await store.save(preferences);
          } on Object {
            // The in-memory fallback remains safe even if repair cannot persist.
          }
        }
      }
      if (message == null && (read.currentCorrupt || read.backupCorrupt)) {
        message = read.source == AveluneAppearanceSource.backup
            ? 'Les préférences ont été restaurées depuis la sauvegarde locale.'
            : 'Les préférences invalides ont été remplacées par les réglages par défaut.';
      }
      _emitReady(
        preferences,
        customIsValid: customIsValid,
        message: message,
      );
    } on Object {
      _emit(
        const AveluneAppearanceState(
          status: AveluneAppearanceControllerStatus.error,
          preferences: AveluneAppearancePreferences(),
          message: 'Les préférences d’apparence sont indisponibles.',
        ),
      );
    }
  }

  Future<bool> selectBackground(String id) async {
    try {
      AveluneAppearanceCatalog.background(id);
    } on ArgumentError {
      return false;
    }
    var customIsValid = false;
    if (id == AveluneAppearanceCatalog.customBackgroundId) {
      customIsValid = await customBackground.isCurrentValid();
      if (!customIsValid) {
        _emitError(
          _state.preferences,
          'Importez une image avant de sélectionner « Mon image ».',
        );
        return false;
      }
    }
    return _save(
      _state.preferences.copyWith(backgroundId: id),
      customIsValid: customIsValid,
    );
  }

  Future<bool> selectFurniture(String id) async {
    try {
      AveluneAppearanceCatalog.furnitureFinish(id);
    } on ArgumentError {
      return false;
    }
    return _save(
      _state.preferences.copyWith(furnitureId: id),
      customIsValid: _state.preferences.backgroundId ==
          AveluneAppearanceCatalog.customBackgroundId,
    );
  }

  Future<bool> importCustomBackground() async {
    final previous = _state.preferences;
    final previousCustomIsValid = _state.customBackgroundPath != null;
    _emit(
      AveluneAppearanceState(
        status: AveluneAppearanceControllerStatus.saving,
        preferences: previous,
      ),
    );
    try {
      final outcome = await customBackground.pickAndImport();
      if (outcome == AveluneCustomBackgroundImportOutcome.cancelled) {
        _emitReady(previous, customIsValid: previousCustomIsValid);
        return false;
      }
      if (!await customBackground.isCurrentValid()) {
        throw const AveluneCustomBackgroundException(
          AveluneCustomBackgroundErrorCode.decodeFailed,
          'La copie locale de l’image n’est pas valide.',
        );
      }
      final next = previous.copyWith(
        backgroundId: AveluneAppearanceCatalog.customBackgroundId,
      );
      await store.save(next);
      _emitReady(next, customIsValid: true);
      return true;
    } on AveluneCustomBackgroundException catch (error) {
      _emitError(
        previous,
        error.message,
        customIsValid: previousCustomIsValid,
      );
      return false;
    } on Object {
      _emitError(
        previous,
        'L’image a été traitée, mais le réglage n’a pas pu être enregistré.',
        customIsValid: previousCustomIsValid,
      );
      return false;
    }
  }

  Future<bool> removeCustomBackground() async {
    final previous = _state.preferences;
    final previousCustomIsValid = _state.customBackgroundPath != null;
    final next = previous.copyWith(
      backgroundId: AveluneAppearanceCatalog.defaultBackgroundId,
    );
    _emit(
      AveluneAppearanceState(
        status: AveluneAppearanceControllerStatus.saving,
        preferences: previous,
      ),
    );
    try {
      await store.save(next);
    } on Object {
      _emitError(
        previous,
        'Le retour au fond Ambre n’a pas pu être enregistré.',
        customIsValid: previousCustomIsValid,
      );
      return false;
    }
    try {
      await customBackground.delete();
    } on Object {
      _emitError(
        next,
        'Le fond Ambre est actif, mais l’ancien fichier n’a pas pu être supprimé.',
      );
      return false;
    }
    _emitReady(next, customIsValid: false);
    return true;
  }

  Future<bool> _save(
    AveluneAppearancePreferences next, {
    required bool customIsValid,
  }) async {
    final previous = _state.preferences;
    final previousCustomIsValid = _state.customBackgroundPath != null;
    if (next == previous) {
      _emitReady(previous, customIsValid: customIsValid);
      return true;
    }
    _emit(
      AveluneAppearanceState(
        status: AveluneAppearanceControllerStatus.saving,
        preferences: previous,
      ),
    );
    try {
      await store.save(next);
      _emitReady(next, customIsValid: customIsValid);
      return true;
    } on Object {
      _emitError(
        previous,
        'Le réglage d’apparence n’a pas pu être enregistré.',
        customIsValid: previousCustomIsValid,
      );
      return false;
    }
  }

  void _emitReady(
    AveluneAppearancePreferences preferences, {
    required bool customIsValid,
    String? message,
  }) {
    final usesCustom = preferences.backgroundId ==
            AveluneAppearanceCatalog.customBackgroundId &&
        customIsValid;
    _emit(
      AveluneAppearanceState(
        status: AveluneAppearanceControllerStatus.ready,
        preferences: preferences,
        customBackgroundPath: usesCustom ? customBackground.imagePath : null,
        customBackgroundThumbnailPath:
            usesCustom ? customBackground.thumbnailPath : null,
        message: message,
      ),
    );
  }

  void _emitError(
    AveluneAppearancePreferences preferences,
    String message, {
    bool customIsValid = false,
  }) {
    final usesCustom = preferences.backgroundId ==
            AveluneAppearanceCatalog.customBackgroundId &&
        customIsValid;
    _emit(
      AveluneAppearanceState(
        status: AveluneAppearanceControllerStatus.error,
        preferences: preferences,
        customBackgroundPath: usesCustom ? customBackground.imagePath : null,
        customBackgroundThumbnailPath:
            usesCustom ? customBackground.thumbnailPath : null,
        message: message,
      ),
    );
  }

  void _emit(AveluneAppearanceState state) {
    _state = state;
    notifyListeners();
  }
}
