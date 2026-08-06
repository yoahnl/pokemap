import 'package:flutter/foundation.dart';

import '../../hub_dashboard_controller.dart';
import '../../hub_game_views.dart';
import 'avelune_home_view_data.dart';
import 'avelune_home_view_data_mapper.dart';

/// Owns only Avelune UI selection and action routing.
///
/// Persistence, package import and game launch remain owned by Hub services and
/// are reached exclusively through [HubUiActions].
final class AveluneHomeController extends ChangeNotifier {
  AveluneHomeController({
    required HubDashboardSnapshot snapshot,
    required this.actions,
    this.mapper = const AveluneHomeViewDataMapper(),
    bool reducedMotion = false,
  })  : _snapshot = snapshot,
        _reducedMotion = reducedMotion {
    _viewData = _map();
    _selectedGameId = _viewData.selectedGameId;
  }

  HubUiActions actions;
  final AveluneHomeViewDataMapper mapper;
  HubDashboardSnapshot _snapshot;
  bool _reducedMotion;
  String? _selectedGameId;
  late AveluneHomeViewData _viewData;

  AveluneHomeViewData get viewData => _viewData;

  bool updateSnapshot(
    HubDashboardSnapshot snapshot, {
    bool? reducedMotion,
  }) {
    final nextReducedMotion = reducedMotion ?? _reducedMotion;
    if (identical(snapshot, _snapshot) && nextReducedMotion == _reducedMotion) {
      return false;
    }
    _snapshot = snapshot;
    _reducedMotion = nextReducedMotion;
    _commitMappedData();
    return true;
  }

  bool selectGame(String gameId) {
    if (_selectedGameId == gameId || _sourceGame(gameId) == null) return false;
    _selectedGameId = gameId;
    _commitMappedData();
    return true;
  }

  bool activatePrimaryAction() {
    final gameData = _viewData.selectedGame;
    if (gameData == null) return false;
    final source = _sourceGame(gameData.id);
    if (source == null) return false;
    switch (gameData.primaryAction) {
      case AvelunePrimaryAction.continueGame:
        final callback = actions.onContinue;
        if (callback == null) return false;
        callback(source);
        return true;
      case AvelunePrimaryAction.play:
        final callback = actions.onNewGame;
        if (callback == null) return false;
        callback(source);
        return true;
      case AvelunePrimaryAction.disabled:
        return false;
    }
  }

  bool activateRecentActivity(String gameId) {
    final activityExists =
        _viewData.recentActivity.any((activity) => activity.gameId == gameId);
    final source = _sourceGame(gameId);
    final callback = actions.onContinue;
    if (!activityExists ||
        source == null ||
        !source.activity.installationHealthy ||
        !source.activity.canContinue ||
        callback == null) {
      return false;
    }
    selectGame(gameId);
    callback(source);
    return true;
  }

  bool requestImport() {
    final callback = actions.onImportRequested;
    if (!_viewData.canImport || callback == null) return false;
    callback();
    return true;
  }

  void _commitMappedData() {
    _viewData = _map();
    _selectedGameId = _viewData.selectedGameId;
    notifyListeners();
  }

  AveluneHomeViewData _map() => mapper.map(
        snapshot: _snapshot,
        selectedGameId: _selectedGameId,
        canImport: actions.onImportRequested != null,
        canContinue: actions.onContinue != null,
        canPlay: actions.onNewGame != null,
        reducedMotion: _reducedMotion,
      );

  HubGameView? _sourceGame(String gameId) {
    for (final game in _snapshot.games) {
      if (game.game.gameId == gameId) return game;
    }
    return null;
  }
}
