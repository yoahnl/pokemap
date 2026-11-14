part of 'studio_playtest_view.dart';

mixin _StudioPlaytestSessionCommands
    on State<StudioPlaytestView>, _StudioPlaytestRuntimeLoading {
  late Future<Object> _loading = _load();
  bool _busy = false;
  String? _message;
  bool _spatialPaused = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    var saved = false;
    try {
      saved = _spatialPlaytest == null
          ? await _game?.saveGame() ?? false
          : await _spatialPlaytest!.save();
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = saved
          ? 'Test enregistré en mémoire pour cette session.'
          : 'Terminez l’interaction avant d’enregistrer le test.';
    });
  }

  Future<void> _resume() async {
    if (_busy || !_ready) return;
    setState(() => _busy = true);
    if (_spatialPlaytest != null) {
      _replaceTest(restoreSpatialSave: true);
      return;
    }
    final loaded = await _game?.loadGame() ?? false;
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = loaded ? 'Sauvegarde du test reprise.' : 'Reprise impossible pendant cette interaction ou après ce changement.';
    });
  }

  Future<void> _newGame() async {
    if (_busy || !_ready) return;
    _replaceTest(restoreSpatialSave: false);
  }

  void _replaceTest({required bool restoreSpatialSave}) {
    final previous = _spatialPlaytest;
    final services = _playerServices;
    _game?.pauseEngine();
    setState(() {
      _playerServices = null;
      _playerBundle = null;
      _game = null;
      _spatialPlaytest = null;
      _spatial = null;
      _ready = false;
      _spatialPaused = false;
      _busy = false;
      _message = restoreSpatialSave
          ? 'Reprise de la sauvegarde du test…'
          : 'Préparation d’une nouvelle partie…';
      _loading = () async {
        await WidgetsBinding.instance.endOfFrame;
        await services?.dispose();
        await previous?.dispose();
        if (!restoreSpatialSave) await _saves.delete();
        if (!mounted) throw StateError('Test fermé');
        final loaded = await _load(restoreSpatialSave: restoreSpatialSave);
        if (mounted) {
          setState(
            () => _message = restoreSpatialSave
                ? 'Sauvegarde du test reprise.'
                : 'Nouvelle partie : état de test réinitialisé.',
          );
        }
        return loaded;
      }();
    });
  }

  Future<void> _toggleSpatialPause() async {
    final runtime = _spatialPlaytest?.runtime;
    if (runtime == null) return;
    if (_spatialPaused) {
      await runtime.resume();
    } else {
      await runtime.pause();
    }
    if (mounted) setState(() => _spatialPaused = !_spatialPaused);
  }
}
