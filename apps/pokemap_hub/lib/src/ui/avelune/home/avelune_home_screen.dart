import 'dart:async';

import 'package:flutter/material.dart';

import '../appearance/avelune_appearance_preferences.dart';
import '../avelune_console.dart';
import '../avelune_theme.dart';
import '../motion/avelune_exchange_controller.dart';
import '../motion/avelune_feedback.dart';
import 'avelune_cartridge_exchange_overlay.dart';
import 'avelune_home_geometry.dart';
import 'avelune_home_view_data.dart';
import 'avelune_room_scene.dart';

class AveluneHomeScreen extends StatefulWidget {
  const AveluneHomeScreen({
    super.key,
    required this.viewData,
    required this.appearance,
    this.customBackground,
    this.consoleState,
    this.insertionProgress = 0,
    this.feedback = const AveluneNoopFeedback(),
    this.onGameSelected,
    this.onAddGame,
    this.onHeroPressed,
    this.onHeroLongPress,
  });

  final AveluneHomeViewData viewData;
  final AveluneAppearancePreferences appearance;
  final ImageProvider<Object>? customBackground;
  final AveluneConsoleState? consoleState;
  final double insertionProgress;
  final AveluneFeedback feedback;
  final ValueChanged<AveluneGameViewData>? onGameSelected;
  final VoidCallback? onAddGame;
  final VoidCallback? onHeroPressed;
  final VoidCallback? onHeroLongPress;

  @override
  State<AveluneHomeScreen> createState() => _AveluneHomeScreenState();
}

class _AveluneHomeScreenState extends State<AveluneHomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _heroAnchorKey = GlobalKey();
  final GlobalKey _exchangeOverlayAnchorKey = GlobalKey();
  final Map<String, GlobalKey> _shelfCartridgeKeys = <String, GlobalKey>{};

  AveluneExchangeController? _exchangeController;
  AnimationController? _exchangeAnimation;
  String? _selectedGameId;
  AveluneGameViewData? _exchangeSource;
  AveluneGameViewData? _exchangeTarget;
  Rect? _sourceShelfRect;
  Rect? _targetShelfRect;
  Rect? _heroRect;
  bool _reducedMotion = false;
  int _exchangeGeneration = 0;

  bool get _isExchanging => _exchangeSource != null;

  @override
  void initState() {
    super.initState();
    _selectedGameId = widget.viewData.selectedGameId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configureMotion();
  }

  @override
  void didUpdateWidget(covariant AveluneHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isExchanging &&
        oldWidget.viewData.selectedGameId != widget.viewData.selectedGameId) {
      _selectedGameId = widget.viewData.selectedGameId;
    }
    if (!_containsGame(_selectedGameId)) {
      _selectedGameId = widget.viewData.selectedGameId ??
          (widget.viewData.games.isEmpty
              ? null
              : widget.viewData.games.first.id);
    }
    _shelfCartridgeKeys.removeWhere(
      (id, _) => !widget.viewData.games.any((game) => game.id == id),
    );
    _configureMotion();
  }

  @override
  void dispose() {
    _exchangeGeneration++;
    _exchangeController?.dispose();
    _exchangeAnimation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final constrainedWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mediaQuery.size.width;
        final constrainedHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mediaQuery.size.height;
        final viewportSize = Size(constrainedWidth, constrainedHeight);
        final geometry = AveluneHomeGeometry.resolve(
          viewportSize: viewportSize,
          safeArea: mediaQuery.padding,
          textScaleFactor: mediaQuery.textScaler.scale(1),
        );
        final selectedGame = _gameFor(_selectedGameId);
        final hiddenShelfIds = _isExchanging
            ? <String>{
                _exchangeSource!.id,
                _exchangeTarget!.id,
              }
            : const <String>{};

        return SizedBox.expand(
          key: const ValueKey<String>('avelune-home-screen'),
          child: AveluneRoomScene(
            geometry: geometry,
            appearance: widget.appearance,
            games: widget.viewData.games,
            selectedGame: selectedGame,
            customBackground: widget.customBackground,
            consoleState: widget.consoleState,
            insertionProgress: widget.insertionProgress,
            onGameSelected: _requestGameSelection,
            onAddGame: widget.onAddGame,
            onHeroPressed: widget.onHeroPressed,
            onHeroLongPress: widget.onHeroLongPress,
            heroAnchorKey: _heroAnchorKey,
            shelfCartridgeKeyFor: _shelfKeyFor,
            hiddenShelfGameIds: hiddenShelfIds,
            showHero: !_isExchanging,
            foregroundOverlay: SizedBox.expand(
              key: _exchangeOverlayAnchorKey,
              child: _buildExchangeOverlay(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExchangeOverlay() {
    final animation = _exchangeAnimation;
    final source = _exchangeSource;
    final target = _exchangeTarget;
    final heroRect = _heroRect;
    final sourceShelfRect = _sourceShelfRect;
    final targetShelfRect = _targetShelfRect;
    if (animation == null ||
        source == null ||
        target == null ||
        heroRect == null ||
        sourceShelfRect == null ||
        targetShelfRect == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => AveluneCartridgeExchangeOverlay(
        key: const ValueKey<String>('avelune-cartridge-exchange-overlay'),
        progress: animation.value,
        sourceGame: source,
        targetGame: _exchangeTarget ?? target,
        heroRect: heroRect,
        sourceShelfRect: sourceShelfRect,
        targetShelfRect: _targetShelfRect ?? targetShelfRect,
        reducedMotion: _reducedMotion,
      ),
    );
  }

  void _configureMotion() {
    final selectedId = _selectedGameId;
    final reducedMotion = widget.viewData.reducedMotion ||
        MediaQuery.maybeOf(context)?.disableAnimations == true;
    final motion =
        reducedMotion ? AveluneMotionTokens.reduced : context.aveluneMotion;
    _reducedMotion = reducedMotion;

    final animation = _exchangeAnimation;
    if (animation == null) {
      _exchangeAnimation = AnimationController(
        vsync: this,
        duration: motion.exchange,
      );
    } else {
      animation.duration = motion.exchange;
    }

    if (selectedId == null) {
      _exchangeController?.dispose();
      _exchangeController = null;
      return;
    }
    final controller = _exchangeController;
    if (controller == null ||
        !controller.isExchanging && controller.currentGameId != selectedId) {
      controller?.dispose();
      _exchangeController = AveluneExchangeController(
        initialGameId: selectedId,
        motion: motion,
        feedback: widget.feedback,
      );
    }
  }

  Future<void> _requestGameSelection(AveluneGameViewData game) async {
    final controller = _exchangeController;
    final animation = _exchangeAnimation;
    final source = _gameFor(controller?.currentGameId ?? _selectedGameId);
    if (controller == null ||
        animation == null ||
        source == null ||
        game.id == controller.currentGameId && !controller.isExchanging) {
      return;
    }

    final targetShelfRect = _rectInOverlay(_shelfKeyFor(game.id));
    if (targetShelfRect == null) return;

    if (controller.isExchanging) {
      setState(() {
        _exchangeTarget = game;
        _targetShelfRect = targetShelfRect;
      });
      unawaited(
        controller.select(game.id, onCommitted: _commitSelection),
      );
      return;
    }

    final heroRect = _rectInOverlay(_heroAnchorKey);
    final sourceShelfRect = _rectInOverlay(_shelfKeyFor(source.id));
    if (heroRect == null) return;
    final generation = ++_exchangeGeneration;
    animation.stop();
    animation.value = 0;
    setState(() {
      _exchangeSource = source;
      _exchangeTarget = game;
      _heroRect = heroRect;
      _sourceShelfRect = sourceShelfRect ?? targetShelfRect;
      _targetShelfRect = targetShelfRect;
    });

    final controllerFuture = controller.select(
      game.id,
      onCommitted: _commitSelection,
    );
    try {
      await Future.wait<void>(<Future<void>>[
        controllerFuture,
        animation.forward().orCancel,
      ]);
    } on TickerCanceled {
      return;
    }
    if (!mounted || generation != _exchangeGeneration) return;
    setState(_clearExchangeVisual);
  }

  void _commitSelection(String gameId) {
    final game = _gameFor(gameId);
    if (!mounted || game == null) return;
    setState(() => _selectedGameId = gameId);
    widget.onGameSelected?.call(game);
  }

  Rect? _rectInOverlay(GlobalKey key) {
    final overlayObject =
        _exchangeOverlayAnchorKey.currentContext?.findRenderObject();
    final targetObject = key.currentContext?.findRenderObject();
    if (overlayObject is! RenderBox ||
        targetObject is! RenderBox ||
        !overlayObject.attached ||
        !targetObject.attached) {
      return null;
    }
    final topLeft = targetObject.localToGlobal(
      Offset.zero,
      ancestor: overlayObject,
    );
    return topLeft & targetObject.size;
  }

  GlobalKey _shelfKeyFor(String gameId) =>
      _shelfCartridgeKeys.putIfAbsent(gameId, GlobalKey.new);

  AveluneGameViewData? _gameFor(String? gameId) {
    if (gameId == null) return null;
    for (final game in widget.viewData.games) {
      if (game.id == gameId) return game;
    }
    return null;
  }

  bool _containsGame(String? gameId) => _gameFor(gameId) != null;

  void _clearExchangeVisual() {
    _exchangeSource = null;
    _exchangeTarget = null;
    _heroRect = null;
    _sourceShelfRect = null;
    _targetShelfRect = null;
  }
}
