import 'package:flutter/widgets.dart';

typedef StudioHomeMap = ({String id, String name});

class StudioHomeNavigation extends ChangeNotifier {
  final search = TextEditingController();
  final searchFocus = FocusNode();
  bool visible = true;
  bool canTest = false;
  List<StudioHomeMap> maps = const [];
  Future<bool> Function()? allowSwitch;
  void Function(String, String?)? onNavigate;
  (String, String?)? _pending;
  bool _disposed = false;

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
    if (onNavigate == null) {
      _pending = (destination, mapId);
    } else {
      onNavigate!(destination, mapId);
    }
    notifyListeners();
  }

  void publish({
    required List<StudioHomeMap> availableMaps,
    required bool testAvailable,
    required void Function(String, String?) navigate,
    required Future<bool> Function() guard,
  }) {
    if (_disposed) return;
    maps = availableMaps;
    canTest = testAvailable;
    onNavigate = navigate;
    allowSwitch = guard;
    final pending = _pending;
    _pending = null;
    if (pending != null) navigate(pending.$1, pending.$2);
    notifyListeners();
  }

  void reset() {
    maps = const [];
    canTest = false;
    onNavigate = null;
    allowSwitch = null;
    _pending = null;
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
