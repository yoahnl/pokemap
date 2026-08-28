import 'package:flutter/foundation.dart';

import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';

enum HubSessionSurface { hub, player }

final class HubSessionController extends ChangeNotifier {
  HubSessionController({required Future<void> Function() refreshHub})
    : _refreshHub = refreshHub;

  final Future<void> Function() _refreshHub;
  HubGameView? _activeGame;

  HubGameView? get activeGame => _activeGame;

  HubSessionSurface get surface =>
      _activeGame == null ? HubSessionSurface.hub : HubSessionSurface.player;

  bool open(HubGameView game) {
    if (_activeGame?.game.gameId == game.game.gameId) return false;
    _activeGame = game;
    notifyListeners();
    return true;
  }

  bool close() {
    if (_activeGame == null) return false;
    _activeGame = null;
    notifyListeners();
    return true;
  }

  Future<bool> returnToHub() async {
    if (!close()) return false;
    await _refreshHub();
    return true;
  }
}
