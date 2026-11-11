import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

import '../../features/home/application/home_navigation_host.dart';

export '../../features/home/application/home_navigation_host.dart'
    show StudioHomeMap;

class StudioHomeNavigation extends ChangeNotifier {
  final search = TextEditingController();
  final searchFocus = FocusNode();
  final _host = HomeNavigationHost();
  bool visible = true;
  Widget Function(String)? mapPreviewBuilder;
  bool _disposed = false;

  bool get canTest => _host.canTest;
  List<StudioHomeMap> get maps => _host.maps;
  ProjectManifest? get mapLibrary => _host.mapLibrary;
  ProjectNewGameConfig? get newGame => _host.newGame;
  Future<bool> Function()? get allowSwitch => _host.allowSwitch;
  set allowSwitch(Future<bool> Function()? guard) => _host.allowSwitch = guard;
  VoidCallback? get onOptimizeLibrary => _host.onOptimizeLibrary;
  bool get optimizingLibrary => _host.optimizingLibrary;
  String? get libraryOptimizationError => _host.libraryOptimizationError;

  void updateLibraryOptimization({
    VoidCallback? onOptimize,
    bool busy = false,
    String? error,
  }) {
    if (_disposed) return;
    _host.updateLibraryOptimization(
      onOptimize: onOptimize,
      busy: busy,
      error: error,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) notifyListeners();
    });
  }

  void showHome() {
    visible = true;
    notifyListeners();
  }

  void searchHome() {
    showHome();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && visible) searchFocus.requestFocus();
    });
  }

  void resume() {
    visible = false;
    notifyListeners();
  }

  void navigate(String destination, [String? mapId]) {
    visible = false;
    _host.navigate(destination, mapId);
    notifyListeners();
  }

  void publish({
    required List<StudioHomeMap> availableMaps,
    ProjectManifest? library,
    ProjectNewGameConfig? startConfig,
    required bool testAvailable,
    Widget Function(String)? previewBuilder,
    required void Function(String, String?) navigate,
    required Future<bool> Function() guard,
  }) {
    if (_disposed) return;
    mapPreviewBuilder = previewBuilder;
    _host.publish(
      availableMaps: availableMaps,
      library: library,
      startConfig: startConfig,
      testAvailable: testAvailable,
      navigate: navigate,
      guard: guard,
    );
    notifyListeners();
  }

  void reset() {
    mapPreviewBuilder = null;
    _host.reset();
  }

  @override
  void dispose() {
    _disposed = true;
    search.dispose();
    searchFocus.dispose();
    super.dispose();
  }
}

class StudioHomeScope extends InheritedWidget {
  const StudioHomeScope({
    super.key,
    required this.navigation,
    required super.child,
  });
  final StudioHomeNavigation navigation;

  static StudioHomeNavigation? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StudioHomeScope>()?.navigation;

  @override
  bool updateShouldNotify(StudioHomeScope oldWidget) =>
      navigation != oldWidget.navigation;
}
