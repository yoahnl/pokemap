import 'package:map_core/map_core_domain.dart';

typedef StudioHomeMap = ({String id, String name});
typedef HomeNavigationHandler = void Function(
  String destination,
  String? mapId,
);

class HomeNavigationHost {
  List<StudioHomeMap> maps = const [];
  ProjectManifest? mapLibrary;
  ProjectNewGameConfig? newGame;
  bool canTest = false;
  Future<bool> Function()? allowSwitch;
  void Function()? onOptimizeLibrary;
  bool optimizingLibrary = false;
  String? libraryOptimizationError;
  HomeNavigationHandler? _handler;
  (String, String?)? _pending;

  bool get connected => _handler != null;
  bool get hasPendingNavigation => _pending != null;

  void updateLibraryOptimization({
    void Function()? onOptimize,
    bool busy = false,
    String? error,
  }) {
    onOptimizeLibrary = onOptimize;
    optimizingLibrary = busy;
    libraryOptimizationError = error;
  }

  void navigate(String destination, [String? mapId]) {
    final handler = _handler;
    if (handler == null) {
      _pending = (destination, mapId);
    } else {
      handler(destination, mapId);
    }
  }

  void publish({
    required List<StudioHomeMap> availableMaps,
    ProjectManifest? library,
    ProjectNewGameConfig? startConfig,
    required bool testAvailable,
    required HomeNavigationHandler navigate,
    required Future<bool> Function() guard,
  }) {
    maps = availableMaps;
    mapLibrary = library;
    newGame = startConfig ?? library?.newGame;
    canTest = testAvailable;
    _handler = navigate;
    allowSwitch = guard;
    final pending = _pending;
    _pending = null;
    if (pending != null) navigate(pending.$1, pending.$2);
  }

  void reset() {
    onOptimizeLibrary = null;
    optimizingLibrary = false;
    libraryOptimizationError = null;
    maps = const [];
    mapLibrary = null;
    newGame = null;
    canTest = false;
    _handler = null;
    allowSwitch = null;
    _pending = null;
  }
}
