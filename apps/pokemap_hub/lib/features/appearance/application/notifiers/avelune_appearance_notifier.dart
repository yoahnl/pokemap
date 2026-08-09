import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_catalog.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_read.dart';
import 'package:pokemap_hub/features/appearance/domain/repositories/avelune_appearance_repository_interface.dart';
import 'package:pokemap_hub/features/appearance/domain/repositories/custom_background_repository_interface.dart';
import 'package:pokemap_hub/app/di/appearance_dependencies_provider.dart';

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
/// Owns the player's Avelune appearance choices.
///
/// Same shape as [HubDashboardNotifier]: synchronous state, async dependencies
/// resolved once by [_wire] at the head of every async entry point, and
/// `build()` returning the same idle state the ChangeNotifier version started
/// from.
final class AveluneAppearanceNotifier extends Notifier<AveluneAppearanceState> {
  late AveluneAppearanceRepositoryInterface store;
  late AveluneCustomBackgroundGateway customBackground;

  bool _wired = false;

  @override
  AveluneAppearanceState build() => const AveluneAppearanceState.idle();

  Future<void> _wire() async {
    if (_wired) return;
    final deps = await ref.read(aveluneAppearanceDependenciesProvider.future);
    store = deps.store;
    customBackground = deps.customBackground;
    _wired = true;
  }

  Future<void> initialize() async {
    await _wire();
    _emit(
      AveluneAppearanceState(
        status: AveluneAppearanceControllerStatus.loading,
        preferences: state.preferences,
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
    await _wire();
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
          state.preferences,
          'Importez une image avant de sélectionner « Mon image ».',
        );
        return false;
      }
    }
    return _save(
      state.preferences.copyWith(backgroundId: id),
      customIsValid: customIsValid,
    );
  }

  Future<bool> selectFurniture(String id) async {
    await _wire();
    try {
      AveluneAppearanceCatalog.furnitureFinish(id);
    } on ArgumentError {
      return false;
    }
    return _save(
      state.preferences.copyWith(furnitureId: id),
      customIsValid: state.preferences.backgroundId ==
          AveluneAppearanceCatalog.customBackgroundId,
    );
  }

  Future<bool> importCustomBackground(AveluneBackgroundSource source) async {
    await _wire();
    final previous = state.preferences;
    final previousCustomIsValid = state.customBackgroundPath != null;
    _emit(
      AveluneAppearanceState(
        status: AveluneAppearanceControllerStatus.saving,
        preferences: previous,
      ),
    );
    try {
      final outcome = await customBackground.pickAndImport(source);
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
    await _wire();
    final previous = state.preferences;
    final previousCustomIsValid = state.customBackgroundPath != null;
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
    final previous = state.preferences;
    final previousCustomIsValid = state.customBackgroundPath != null;
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

  void _emit(AveluneAppearanceState next) => state = next;
}

final aveluneAppearanceNotifierProvider =
    NotifierProvider<AveluneAppearanceNotifier, AveluneAppearanceState>(
  AveluneAppearanceNotifier.new,
);
