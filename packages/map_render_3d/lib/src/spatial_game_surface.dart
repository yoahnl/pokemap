import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

class SpatialGameSurface<T extends Game> extends StatefulWidget {
  const SpatialGameSurface({
    super.key,
    required this.game,
    required this.loadingBuilder,
    required this.errorBuilder,
    this.autofocus = false,
  });
  final T game;
  final bool autofocus;
  final Widget Function(BuildContext) loadingBuilder;
  final Widget Function(BuildContext, Object) errorBuilder;
  @override
  State<SpatialGameSurface<T>> createState() => _SpatialGameSurfaceState<T>();
}

class _SpatialGameSurfaceState<T extends Game>
    extends State<SpatialGameSurface<T>>
    with WidgetsBindingObserver {
  bool _pausedByVisibility = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncActivity();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncActivity();
  }

  @override
  void didUpdateWidget(SpatialGameSurface<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.game, widget.game)) {
      _pausedByVisibility = false;
    }
    _syncActivity();
  }

  void _syncActivity() {
    if (!TickerMode.valuesOf(context).enabled) {
      if (!widget.game.isPaused) {
        widget.game.pauseEngine();
        _pausedByVisibility = true;
      }
    } else if (_pausedByVisibility) {
      _pausedByVisibility = false;
      widget.game.resumeEngine();
    }
  }

  @override
  Widget build(BuildContext context) => GameWidget<T>(
    game: widget.game,
    autofocus: widget.autofocus,
    loadingBuilder: widget.loadingBuilder,
    errorBuilder: widget.errorBuilder,
  );
}
