import 'package:flutter/widgets.dart';

abstract interface class RenderSurfaceEngine {
  bool get isAttached;
  bool get isPaused;
  void pause();
  void resume();
  void presentFrame();
}

class RenderSurfaceActivity extends StatefulWidget {
  const RenderSurfaceActivity({
    super.key,
    required this.engine,
    required this.child,
    this.continuous = true,
  });

  final RenderSurfaceEngine engine;
  final bool continuous;
  final Widget child;

  @override
  State<RenderSurfaceActivity> createState() => _RenderSurfaceActivityState();
}

class _RenderSurfaceActivityState extends State<RenderSurfaceActivity>
    with WidgetsBindingObserver {
  bool _pausedByVisibility = false;
  bool _pausedByDemand = false;
  bool _demandCheckScheduled = false;

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
  void didUpdateWidget(RenderSurfaceActivity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine != widget.engine) {
      _pausedByVisibility = false;
      _pausedByDemand = false;
    }
    _syncActivity();
  }

  void _syncActivity() {
    final engine = widget.engine;
    if (!TickerMode.valuesOf(context).enabled) {
      if (!engine.isPaused) {
        engine.pause();
        _pausedByVisibility = true;
      }
      return;
    }
    if (_pausedByVisibility) {
      _pausedByVisibility = false;
      engine.resume();
    }
    if (widget.continuous) {
      if (_pausedByDemand) {
        _pausedByDemand = false;
        engine.resume();
      }
    } else if (!engine.isAttached) {
      if (_demandCheckScheduled) return;
      _demandCheckScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _demandCheckScheduled = false;
        if (mounted) _syncActivity();
      });
    } else if (!engine.isPaused || _pausedByDemand) {
      _pausedByDemand = true;
      engine.pause();
      engine.presentFrame();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
