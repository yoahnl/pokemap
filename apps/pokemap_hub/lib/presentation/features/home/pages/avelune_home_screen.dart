import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_console.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_exchange_controller.dart';
import 'package:pokemap_hub/presentation/design_system/motion/avelune_feedback.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_insertion_controller.dart';
import 'package:pokemap_hub/presentation/design_system/motion/avelune_interaction_state.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_cartridge_exchange_overlay.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_cartridge_insertion_overlay.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_hero_details_panel.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_geometry.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_home_header.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_room_scene.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_game_presentation.dart';

typedef AveluneGameLaunchCallback = FutureOr<void> Function(
  AveluneGameViewData game,
);
typedef AveluneLaunchErrorCallback = void Function(
  AveluneGameViewData game,
  Object error,
);

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
    this.onContinue,
    this.onNewGame,
    this.onLaunchError,
    this.onShowDetails,
    this.referenceTime,
    this.productName = 'Avelune',
  });

  final AveluneHomeViewData viewData;
  final AveluneAppearancePreferences appearance;
  final ImageProvider<Object>? customBackground;
  final AveluneConsoleState? consoleState;
  final double insertionProgress;
  final AveluneFeedback feedback;
  final ValueChanged<AveluneGameViewData>? onGameSelected;
  final VoidCallback? onAddGame;
  final AveluneGameLaunchCallback? onContinue;
  final AveluneGameLaunchCallback? onNewGame;
  final AveluneLaunchErrorCallback? onLaunchError;

  /// Raised by the visible details control and by the hero long press.
  final ValueChanged<AveluneGameViewData>? onShowDetails;

  /// Fixed clock for deterministic relative wording in tests and goldens.
  final DateTime? referenceTime;

  /// Injected product identity shown as the header wordmark.
  final String productName;

  @override
  State<AveluneHomeScreen> createState() => _AveluneHomeScreenState();
}

class _AveluneHomeScreenState extends State<AveluneHomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _heroAnchorKey = GlobalKey();
  final GlobalKey _exchangeOverlayAnchorKey = GlobalKey();
  final Map<String, GlobalKey> _shelfCartridgeKeys = <String, GlobalKey>{};
  final List<String> _shelfGameIds = <String>[];

  AveluneExchangeController? _exchangeController;
  AveluneInsertionController? _insertionController;
  AnimationController? _exchangeAnimation;
  AveluneFeedback? _configuredFeedback;
  AveluneMotionTokens _motion = AveluneMotionTokens.standard;
  String? _selectedGameId;
  AveluneGameViewData? _exchangeSource;
  AveluneGameViewData? _exchangeTarget;
  AveluneGameViewData? _insertionGame;
  AveluneInteractionState _insertionState = AveluneInteractionState.idle;
  Rect? _sourceShelfRect;
  Rect? _targetShelfRect;
  Rect? _heroRect;
  Rect? _insertionHeroRect;
  String? _launchErrorMessage;
  String? _detailsHeroShelfGameId;
  bool _reducedMotion = false;
  int _exchangeGeneration = 0;
  int _insertionGeneration = 0;
  int _detailsRevealGeneration = 0;

  bool get _isExchanging => _exchangeSource != null;
  bool get _isInserting => _insertionGame != null;

  @override
  void initState() {
    super.initState();
    _selectedGameId = widget.viewData.selectedGameId;
    _syncShelfGameIds();
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
      _detailsHeroShelfGameId = null;
    }
    if (!_containsGame(_selectedGameId)) {
      _selectedGameId = widget.viewData.selectedGameId ??
          (widget.viewData.games.isEmpty
              ? null
              : widget.viewData.games.first.id);
    }
    _syncShelfGameIds();
    _shelfCartridgeKeys.removeWhere(
      (id, _) => !widget.viewData.games.any((game) => game.id == id),
    );
    _configureMotion();
  }

  @override
  void dispose() {
    _exchangeGeneration++;
    _insertionGeneration++;
    _disposeInteractionControllers();
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
        final canLaunch = selectedGame != null && _canLaunch(selectedGame);
        // Chrome tied to the hero steps aside while the cartridge is animating
        // between the shelf and the console slot.
        final showChrome = !_isExchanging && !_isInserting;
        final detailsPanelRect = _detailsPanelRect(geometry);

        return SizedBox.expand(
          key: const ValueKey<String>('avelune-home-screen'),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              AveluneRoomScene(
                geometry: geometry,
                appearance: widget.appearance,
                games: _shelfGames,
                selectedGame: selectedGame,
                customBackground: widget.customBackground,
                consoleState: _consoleState,
                insertionProgress: _consoleInsertionProgress,
                referenceTime: widget.referenceTime,
                onGameSelected: _requestGameSelection,
                onShelfGameLongPress: widget.onShowDetails == null
                    ? null
                    : _requestShelfGameDetails,
                onAddGame: widget.onAddGame,
                onHeroPressed:
                    canLaunch && !_isExchanging ? _requestInsertion : null,
                onHeroLongPress: _detailsCallbackFor(
                  selectedGame,
                  fromShelf: false,
                ),
                heroAnchorKey: _heroAnchorKey,
                heroArtworkHeroTag:
                    _detailsHeroShelfGameId == null && selectedGame != null
                        ? aveluneArtworkHeroTag(selectedGame.id)
                        : null,
                shelfCartridgeKeyFor: _shelfKeyFor,
                shelfArtworkHeroGameId: _detailsHeroShelfGameId,
                hiddenShelfGameIds: hiddenShelfIds,
                showHero: !_isExchanging && !_isInserting,
                heroSemanticsLabel:
                    canLaunch ? _heroActionLabel(selectedGame) : null,
                showPlayHint: canLaunch && showChrome,
                insertionOverlay: _buildInsertionOverlay(geometry),
                foregroundOverlay: SizedBox.expand(
                  key: _exchangeOverlayAnchorKey,
                  child: _buildExchangeOverlay(),
                ),
              ),
              Positioned.fromRect(
                rect: geometry.headerRect,
                child: AveluneHomeHeader(
                  productName: widget.productName,
                  compact: geometry.sizeClass == AveluneHomeSizeClass.compact,
                ),
              ),
              if (selectedGame case final game?) ...<Widget>[
                Positioned.fromRect(
                  rect: detailsPanelRect,
                  child: Visibility(
                    visible: showChrome,
                    maintainState: true,
                    child: FittedBox(
                      // The home has a no-vertical-scroll contract, so the
                      // column scales down rather than overflowing at large
                      // text scales. The inner SizedBox pins the width first:
                      // FittedBox lays its child out unbounded, so without it
                      // the copy would never wrap and the whole column would be
                      // scaled down to fit one long line.
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: detailsPanelRect.width,
                        child: AveluneHeroDetailsPanel(
                          key: ValueKey<String>(
                            'avelune-hero-details-${game.id}-'
                            '$_detailsRevealGeneration',
                          ),
                          game: game,
                          referenceTime: widget.referenceTime ?? DateTime.now(),
                          condensed: geometry.hidesNonEssentialMetadata,
                          onShowDetails: widget.onShowDetails,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (_launchErrorMessage case final message?)
                Positioned(
                  key: const ValueKey<String>('avelune-launch-error-notice'),
                  left: geometry.contentRect.left + AveluneSpacing.md,
                  right: viewportSize.width -
                      geometry.contentRect.right +
                      AveluneSpacing.md,
                  top: geometry.headerRect.bottom + AveluneSpacing.sm,
                  child: IgnorePointer(
                    child: AveluneStateMessage(
                      kind: AveluneStateMessageKind.error,
                      title: _localized(
                        'Lancement impossible',
                        'Unable to launch',
                      ),
                      message: message,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  VoidCallback? _detailsCallbackFor(
    AveluneGameViewData? game, {
    required bool fromShelf,
  }) {
    final callback = widget.onShowDetails;
    if (game == null || callback == null) return null;
    return () => unawaited(_requestDetails(game, fromShelf: fromShelf));
  }

  void _requestShelfGameDetails(AveluneGameViewData game) =>
      unawaited(_requestDetails(game, fromShelf: true));

  Future<void> _requestDetails(
    AveluneGameViewData game, {
    required bool fromShelf,
  }) async {
    final callback = widget.onShowDetails;
    if (callback == null || _isExchanging || _isInserting) return;

    widget.feedback.emit(AveluneFeedbackCue.details);
    final shelfHeroGameId = fromShelf ? game.id : null;
    if (_detailsHeroShelfGameId != shelfHeroGameId) {
      setState(() => _detailsHeroShelfGameId = shelfHeroGameId);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    callback(game);
  }

  /// Editorial identity block inside the panoramic window, above the hero.
  Rect _detailsPanelRect(AveluneHomeGeometry geometry) => Rect.fromLTRB(
        geometry.cabinWindowRect.left + AveluneSpacing.xxl,
        geometry.headerRect.bottom +
            (geometry.sizeClass == AveluneHomeSizeClass.compact
                ? AveluneSpacing.xs
                : AveluneSpacing.xxl),
        geometry.cabinWindowRect.right - AveluneSpacing.xxl,
        geometry.heroCartridgeRect.top - AveluneSpacing.sm,
      );

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

  Widget? _buildInsertionOverlay(AveluneHomeGeometry geometry) {
    final game = _insertionGame;
    final heroRect = _insertionHeroRect;
    if (game == null || heroRect == null) return null;
    return AveluneCartridgeInsertionOverlay(
      game: game,
      state: _insertionState,
      heroRect: heroRect,
      trajectory: geometry.anchors.insertion,
      motion: _motion,
      reducedMotion: _reducedMotion,
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
      _disposeInteractionControllers();
      return;
    }

    final configurationChanged =
        _motion != motion || !identical(_configuredFeedback, widget.feedback);
    if (configurationChanged && !_isExchanging && !_isInserting) {
      _disposeInteractionControllers();
    }
    _motion = motion;
    _configuredFeedback = widget.feedback;

    _insertionController ??= _createInsertionController();
    final exchange = _exchangeController;
    if (exchange == null ||
        !exchange.isExchanging && exchange.currentGameId != selectedId) {
      exchange?.dispose();
      _exchangeController = AveluneExchangeController(
        initialGameId: selectedId,
        motion: motion,
        feedback: widget.feedback,
        isSelectionBlocked: () =>
            _insertionController?.isInserting == true || _isInserting,
      );
    }
  }

  AveluneInsertionController _createInsertionController() {
    final controller = AveluneInsertionController(
      motion: _motion,
      feedback: widget.feedback,
    );
    controller.addListener(_handleInsertionStateChanged);
    return controller;
  }

  void _disposeInteractionControllers() {
    final insertion = _insertionController;
    insertion?.removeListener(_handleInsertionStateChanged);
    insertion?.dispose();
    _insertionController = null;
    _exchangeController?.dispose();
    _exchangeController = null;
  }

  void _handleInsertionStateChanged() {
    final controller = _insertionController;
    if (!mounted || controller == null) return;
    setState(() => _insertionState = controller.state);
  }

  Future<void> _requestGameSelection(AveluneGameViewData game) async {
    final controller = _exchangeController;
    final animation = _exchangeAnimation;
    final source = _gameFor(controller?.currentGameId ?? _selectedGameId);
    if (_isInserting ||
        controller == null ||
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
        _sourceShelfRect = targetShelfRect;
        _targetShelfRect = targetShelfRect;
      });
      unawaited(
        controller.select(game.id, onCommitted: _commitSelection),
      );
      return;
    }

    final heroRect = _rectInOverlay(_heroAnchorKey);
    if (heroRect == null) return;
    final generation = ++_exchangeGeneration;
    animation.stop();
    animation.value = 0;
    setState(() {
      _exchangeSource = source;
      _exchangeTarget = game;
      _heroRect = heroRect;
      _sourceShelfRect = targetShelfRect;
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

  Future<void> _requestInsertion() async {
    final game = _gameFor(_selectedGameId);
    final controller = _insertionController;
    final heroRect = _rectInOverlay(_heroAnchorKey);
    if (game == null ||
        controller == null ||
        heroRect == null ||
        _isExchanging ||
        _isInserting ||
        !_canLaunch(game)) {
      return;
    }

    final generation = ++_insertionGeneration;
    setState(() {
      _launchErrorMessage = null;
      _insertionGame = game;
      _insertionHeroRect = heroRect;
      _insertionState = AveluneInteractionState.idle;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || generation != _insertionGeneration) return;

    try {
      final launched = await controller.insert(
        onLaunch: () => _launch(game),
      );
      if (!mounted || generation != _insertionGeneration) return;
      if (launched) setState(_clearInsertionVisual);
    } catch (error) {
      if (!mounted || generation != _insertionGeneration) return;
      widget.onLaunchError?.call(game, error);
      setState(() {
        _launchErrorMessage = _localized(
          'Impossible de lancer ${game.title}. Vérifiez la sauvegarde et réessayez.',
          'Unable to launch ${game.title}. Check the save and try again.',
        );
      });
      controller.recover();
      await Future<void>.delayed(_motion.selection);
      if (!mounted || generation != _insertionGeneration) return;
      setState(_clearInsertionVisual);
    }
  }

  Future<void> _launch(AveluneGameViewData game) async {
    switch (game.primaryAction) {
      case AvelunePrimaryAction.continueGame:
        await Future<void>.sync(() => widget.onContinue!(game));
      case AvelunePrimaryAction.play:
        await Future<void>.sync(() => widget.onNewGame!(game));
      case AvelunePrimaryAction.disabled:
        throw StateError('A disabled Avelune game cannot be launched.');
    }
  }

  bool _canLaunch(AveluneGameViewData game) {
    if (!game.isValid || widget.viewData.import.isImporting) return false;
    return switch (game.primaryAction) {
      AvelunePrimaryAction.continueGame => widget.onContinue != null,
      AvelunePrimaryAction.play => widget.onNewGame != null,
      AvelunePrimaryAction.disabled => false,
    };
  }

  String _heroActionLabel(AveluneGameViewData game) =>
      switch (game.primaryAction) {
        AvelunePrimaryAction.continueGame =>
          _localized('Continuer ${game.title}', 'Continue ${game.title}'),
        AvelunePrimaryAction.play =>
          _localized('Jouer à ${game.title}', 'Play ${game.title}'),
        AvelunePrimaryAction.disabled => game.title,
      };

  AveluneConsoleState? get _consoleState => switch (_insertionState) {
        AveluneInteractionState.aligning ||
        AveluneInteractionState.descending =>
          AveluneConsoleState.inserting,
        AveluneInteractionState.latched => AveluneConsoleState.latched,
        AveluneInteractionState.launching => AveluneConsoleState.launching,
        AveluneInteractionState.error => AveluneConsoleState.error,
        _ => widget.consoleState,
      };

  double get _consoleInsertionProgress => switch (_insertionState) {
        AveluneInteractionState.aligning => 0.15,
        AveluneInteractionState.descending => 0.65,
        AveluneInteractionState.latched ||
        AveluneInteractionState.launching =>
          1,
        _ => widget.insertionProgress,
      };

  void _commitSelection(String gameId) {
    final game = _gameFor(gameId);
    if (!mounted || game == null) return;
    setState(() {
      final sourceGameId = _selectedGameId;
      final targetSlot = _shelfGameIds.indexOf(gameId);
      if (targetSlot >= 0 && sourceGameId != null) {
        _shelfGameIds[targetSlot] = sourceGameId;
      }
      _selectedGameId = gameId;
      _detailsHeroShelfGameId = null;
      _syncShelfGameIds();
    });
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

  List<AveluneGameViewData> get _shelfGames => _shelfGameIds
      .map(_gameFor)
      .whereType<AveluneGameViewData>()
      .toList(growable: false);

  void _syncShelfGameIds() {
    final availableIds = widget.viewData.games
        .map((game) => game.id)
        .where((id) => id != _selectedGameId)
        .toList(growable: false);
    final availableSet = availableIds.toSet();
    _shelfGameIds.removeWhere((id) => !availableSet.contains(id));
    for (final id in availableIds) {
      if (!_shelfGameIds.contains(id)) _shelfGameIds.add(id);
    }
  }

  String _localized(String french, String english) =>
      Localizations.maybeLocaleOf(context)?.languageCode == 'fr'
          ? french
          : english;

  void _clearExchangeVisual() {
    _exchangeSource = null;
    _exchangeTarget = null;
    _heroRect = null;
    _sourceShelfRect = null;
    _targetShelfRect = null;
    _detailsRevealGeneration++;
  }

  void _clearInsertionVisual() {
    _insertionGame = null;
    _insertionHeroRect = null;
    _insertionState = AveluneInteractionState.idle;
  }
}
