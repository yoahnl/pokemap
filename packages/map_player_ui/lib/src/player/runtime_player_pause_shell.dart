import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_layout_theme.dart';
import '../theme/pokemap_player_surface_palette_theme.dart';
import '../theme/pokemap_player_window_theme.dart';
import 'player_pause_menu.dart';
import 'runtime_player_actions.dart';
import 'runtime_player_focus_controller.dart';
import 'runtime_player_layout.dart';

class RuntimePlayerPauseShell extends StatefulWidget {
  const RuntimePlayerPauseShell({
    super.key,
    required this.gameTitle,
    required this.pauseSection,
    required this.actions,
    required this.onSelected,
    required this.onBackToRoot,
    required this.detail,
    this.onTouchMenu,
    this.activeInputSource,
    this.logicalSelectionId,
    this.focusController,
    this.saveMessage,
    this.detailTitle,
    this.detailSurfaceRole,
    this.labels = const PlayerPauseMenuLabels(),
    this.presentation,
  });

  const RuntimePlayerPauseShell.root({
    super.key,
    required this.gameTitle,
    required this.actions,
    required this.onSelected,
    required this.detail,
    this.onTouchMenu,
    this.activeInputSource,
    this.logicalSelectionId,
    this.focusController,
    this.saveMessage,
    this.detailTitle,
    this.detailSurfaceRole,
    this.labels = const PlayerPauseMenuLabels(),
    this.presentation,
  })  : pauseSection = RuntimePlayerPauseSection.root,
        onBackToRoot = _noop;

  final String gameTitle;
  final RuntimePlayerPauseSection pauseSection;
  final Map<PlayerPauseAction, PlayerActionAvailability> actions;
  final ValueChanged<PlayerPauseAction> onSelected;
  final VoidCallback onBackToRoot;
  final Widget detail;
  final VoidCallback? onTouchMenu;
  final PlayerInputSource? activeInputSource;
  final String? logicalSelectionId;
  final RuntimePlayerFocusController? focusController;
  final String? saveMessage;
  final String? detailTitle;
  final ProjectPresentationSurfaceRole? detailSurfaceRole;
  final PlayerPauseMenuLabels labels;
  final PlayerPausePresentation? presentation;

  static void _noop() {}

  @override
  State<RuntimePlayerPauseShell> createState() =>
      _RuntimePlayerPauseShellState();
}

class _RuntimePlayerPauseShellState extends State<RuntimePlayerPauseShell> {
  late RuntimePlayerFocusController _focusController;
  late bool _ownsFocusController;
  final Map<RuntimePlayerLayoutClass, ScrollController>
      _navigationScrollControllers =
      <RuntimePlayerLayoutClass, ScrollController>{};
  final Map<RuntimePlayerLayoutClass, ScrollController>
      _detailScrollControllers = <RuntimePlayerLayoutClass, ScrollController>{};
  final Map<RuntimePlayerLayoutClass, double> _navigationScrollOffsets =
      <RuntimePlayerLayoutClass, double>{};
  final Map<RuntimePlayerLayoutClass, double> _detailScrollOffsets =
      <RuntimePlayerLayoutClass, double>{};
  RuntimePlayerLayoutClass? _lastLayout;
  int _scrollRestoreGeneration = 0;

  @override
  void initState() {
    super.initState();
    _attachFocusController();
    _applyExternalFocusState();
  }

  @override
  void didUpdateWidget(covariant RuntimePlayerPauseShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusController != widget.focusController) {
      _detachFocusController();
      _attachFocusController();
    }
    _applyExternalFocusState();
  }

  void _attachFocusController() {
    _ownsFocusController = widget.focusController == null;
    _focusController = widget.focusController ?? RuntimePlayerFocusController();
    _focusController.addListener(_onFocusStateChanged);
  }

  void _detachFocusController() {
    _focusController.removeListener(_onFocusStateChanged);
    if (_ownsFocusController) _focusController.dispose();
  }

  void _applyExternalFocusState() {
    if (widget.activeInputSource case final source?) {
      _focusController.noteInputSource(source);
    }
    _focusController.restoreSelection(
      _availableSelectionId(widget.logicalSelectionId),
    );
  }

  String? _availableSelectionId(String? preferred) {
    final availableSelectionIds = _presentation.visibleActions
        .where((action) => widget.actions[action]?.isEnabled == true)
        .map((action) => 'pause.${action.name}')
        .toList(growable: false);
    if (availableSelectionIds.contains(preferred)) return preferred;
    final current = _focusController.logicalSelectionId;
    if (availableSelectionIds.contains(current)) return current;
    if (preferred == null && current == null) return null;
    return availableSelectionIds.firstOrNull;
  }

  void _onFocusStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _detachFocusController();
    for (final controller in _navigationScrollControllers.values) {
      controller.dispose();
    }
    for (final controller in _detailScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PlayerSurfacePaletteScope(
        role: ProjectPresentationSurfaceRole.pauseMenu,
        child: Builder(
          builder: (context) =>
              PlayerPauseSurface.composed(child: _buildSurface(context)),
        ),
      );

  Widget _buildSurface(BuildContext context) {
    return RuntimePlayerActions(
      onBack: widget.onBackToRoot,
      onMenu: widget.onTouchMenu ?? widget.onBackToRoot,
      onInputSourceChanged: _focusController.noteInputSource,
      child: MouseRegion(
        onHover: (_) =>
            _focusController.noteInputSource(PlayerInputSource.mouse),
        child: Listener(
          onPointerDown: (event) {
            final source = switch (event.kind) {
              PointerDeviceKind.mouse => PlayerInputSource.mouse,
              PointerDeviceKind.touch ||
              PointerDeviceKind.stylus =>
                PlayerInputSource.touch,
              PointerDeviceKind.invertedStylus ||
              PointerDeviceKind.trackpad ||
              PointerDeviceKind.unknown =>
                _focusController.activeInputSource,
            };
            _focusController.noteInputSource(source);
          },
          child: Material(
            key: const ValueKey<String>('runtime-pause-backdrop'),
            color: context.playerPauseBackdropColor,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final resolved = context.playerLayoutTheme?.resolve(
                    ProjectPresentationSurfaceRole.pauseMenu,
                    constraints,
                  );
                  final layout = resolved == null
                      ? classifyRuntimePlayerLayout(constraints)
                      : switch (resolved.breakpoint) {
                          ProjectPresentationBreakpoint.compact =>
                            constraints.maxHeight > constraints.maxWidth
                                ? RuntimePlayerLayoutClass.compactPortrait
                                : RuntimePlayerLayoutClass.compactLandscape,
                          ProjectPresentationBreakpoint.regular =>
                            RuntimePlayerLayoutClass.compactLandscape,
                          ProjectPresentationBreakpoint.expanded =>
                            RuntimePlayerLayoutClass.expanded,
                        };
                  if (_lastLayout != layout) {
                    _rememberScrollOffsets(_lastLayout);
                    _lastLayout = layout;
                    _focusController.restoreSelection(
                      _availableSelectionId(
                        widget.logicalSelectionId ??
                            _focusController.logicalSelectionId,
                      ),
                    );
                    _restoreScrollOffsetsAfterLayout(layout);
                  }
                  final composition = _composition(layout);
                  return Stack(
                    key: ValueKey<String>(resolved == null
                        ? 'runtime-pause-layout-${layout.name}'
                        : 'runtime-pause-responsive-'
                            '${resolved.breakpoint.name}'),
                    fit: StackFit.expand,
                    children: <Widget>[
                      switch (layout) {
                        RuntimePlayerLayoutClass.compactPortrait =>
                          _compactPortrait(
                            context,
                            layout,
                            resolved,
                            composition,
                          ),
                        RuntimePlayerLayoutClass.compactLandscape => _twoColumn(
                            context,
                            layout: layout,
                            widthFactor: .78,
                            navigationWidth: 220,
                            resolved: resolved,
                            composition: composition,
                          ),
                        RuntimePlayerLayoutClass.expanded => _twoColumn(
                            context,
                            layout: layout,
                            widthFactor: null,
                            navigationWidth: 280,
                            resolved: resolved,
                            composition: composition,
                          ),
                      },
                      if (layout != RuntimePlayerLayoutClass.expanded &&
                          widget.onTouchMenu != null)
                        Positioned(
                          top: PlayerSpacing.sm,
                          right: PlayerSpacing.sm,
                          child: AnimatedOpacity(
                            key: const ValueKey<String>(
                              'runtime-pause-touch-menu-opacity',
                            ),
                            opacity: _focusController.activeInputSource ==
                                    PlayerInputSource.controller
                                ? .42
                                : 1,
                            duration: context.playerMotion.fast,
                            child: IconButton.filled(
                              key: const ValueKey<String>(
                                'runtime-pause-touch-menu',
                              ),
                              tooltip: context.playerL10n.resume,
                              onPressed: widget.onTouchMenu,
                              constraints: const BoxConstraints.tightFor(
                                width: 56,
                                height: 56,
                              ),
                              icon: const Icon(Icons.pause_rounded),
                            ),
                          ),
                        ),
                      if (widget.saveMessage case final message?
                          when message.trim().isNotEmpty)
                        Positioned(
                          left: PlayerSpacing.md,
                          right: PlayerSpacing.md,
                          bottom: PlayerSpacing.md,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: Semantics(
                                liveRegion: true,
                                child: PlayerPanel(
                                  key: const ValueKey<String>(
                                    'runtime-save-receipt',
                                  ),
                                  elevated: true,
                                  surfaceRole:
                                      ProjectPresentationSurfaceRole.save,
                                  padding: const EdgeInsets.all(
                                    PlayerSpacing.sm,
                                  ),
                                  child: Text(
                                    message,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactPortrait(
    BuildContext context,
    RuntimePlayerLayoutClass layout,
    ProjectResolvedSurfaceLayout? resolved,
    ProjectPauseCompositionVariantProfile? composition,
  ) {
    final panelPadding = EdgeInsets.all(
      PlayerSpacing.md * (resolved?.spacingScale ?? 1),
    );
    if (widget.pauseSection != RuntimePlayerPauseSection.root) {
      return PlayerPanel(
        role: PlayerPanelRole.menu,
        surfaceRole:
            widget.detailSurfaceRole ?? _surfaceRoleFor(widget.pauseSection),
        padding: panelPadding,
        child: _detailPane(context, layout),
      );
    }
    final fullScreen =
        resolved?.variant.slot == ProjectPresentationLayoutSlot.fullScreen;
    final margin = resolved?.additionalSafeAreaPadding ?? 0;
    return Align(
      alignment: fullScreen ? Alignment.center : Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: fullScreen ? 1 : .86,
        widthFactor: resolved?.maxWidthFactor ?? 1,
        child: Padding(
          padding: EdgeInsets.all(margin),
          child: PlayerPanel(
            role: PlayerPanelRole.menu,
            surfaceRole: ProjectPresentationSurfaceRole.pauseMenu,
            padding: panelPadding,
            elevated: true,
            child: composition?.showRootDetailPanel == true
                ? Column(
                    children: <Widget>[
                      Expanded(
                        child: _navigation(
                          layout,
                          resolved: resolved,
                          composition: composition,
                        ),
                      ),
                      const SizedBox(height: PlayerSpacing.sm),
                      SizedBox(
                        height: 180,
                        child: _detailPane(context, layout),
                      ),
                    ],
                  )
                : _navigation(
                    layout,
                    resolved: resolved,
                    composition: composition,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _twoColumn(
    BuildContext context, {
    required RuntimePlayerLayoutClass layout,
    required double? widthFactor,
    required double navigationWidth,
    required ProjectResolvedSurfaceLayout? resolved,
    required ProjectPauseCompositionVariantProfile? composition,
  }) {
    final effectiveWidthFactor = resolved?.maxWidthFactor ?? widthFactor;
    final margin = resolved?.additionalSafeAreaPadding ?? PlayerSpacing.md;
    final alignment = switch (resolved?.variant.slot) {
      ProjectPresentationLayoutSlot.left ||
      ProjectPresentationLayoutSlot.leftPane =>
        Alignment.centerLeft,
      ProjectPresentationLayoutSlot.center => Alignment.center,
      ProjectPresentationLayoutSlot.right => Alignment.centerRight,
      _ => Alignment.centerRight,
    };
    Widget panel = ConstrainedBox(
      key: effectiveWidthFactor == null
          ? const ValueKey<String>('runtime-pause-expanded-panel')
          : null,
      constraints: BoxConstraints(
        maxWidth: effectiveWidthFactor == null ? 820 : double.infinity,
      ),
      child: PlayerPanel(
        role: PlayerPanelRole.menu,
        surfaceRole: ProjectPresentationSurfaceRole.pauseMenu,
        padding: EdgeInsets.all(
          PlayerSpacing.md * (resolved?.spacingScale ?? 1),
        ),
        elevated: true,
        child: widget.pauseSection == RuntimePlayerPauseSection.root &&
                composition?.showRootDetailPanel == false
            ? _navigation(
                layout,
                resolved: resolved,
                composition: composition,
                scrollKey: const ValueKey<String>(
                  'runtime-pause-navigation-scroll',
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    width: navigationWidth,
                    child: _navigation(
                      layout,
                      resolved: resolved,
                      composition: composition,
                      scrollKey: const ValueKey<String>(
                        'runtime-pause-navigation-scroll',
                      ),
                    ),
                  ),
                  const SizedBox(width: PlayerSpacing.md),
                  Expanded(child: _detailPane(context, layout)),
                ],
              ),
      ),
    );
    if (effectiveWidthFactor != null) {
      panel = FractionallySizedBox(
        widthFactor: effectiveWidthFactor,
        child: panel,
      );
    }
    return Padding(
      padding: EdgeInsets.all(margin),
      child: Align(
        alignment: alignment,
        child: panel,
      ),
    );
  }

  Widget _navigation(
    RuntimePlayerLayoutClass layout, {
    Key? scrollKey,
    ProjectResolvedSurfaceLayout? resolved,
    ProjectPauseCompositionVariantProfile? composition,
  }) {
    final controller = _navigationScrollControllers.putIfAbsent(
      layout,
      () => ScrollController(
        debugLabel: 'Runtime pause navigation ${layout.name}',
      ),
    );
    return Scrollbar(
      key: const ValueKey<String>('runtime-pause-navigation-scrollbar'),
      controller: controller,
      thumbVisibility: true,
      child: PlayerPauseNavigation(
        gameTitle: widget.gameTitle,
        actions: widget.actions,
        onSelected: widget.onSelected,
        scrollKey: scrollKey,
        scrollController: controller,
        focusController: _focusController,
        labels: widget.labels,
        presentation: widget.presentation,
        showGameTitle: resolved == null ||
            resolved.variant.visibleSecondaryElements.contains(
              ProjectPresentationSecondaryElement.pauseGameTitle,
            ),
        composition: composition,
        compositionLayoutName: layout.name,
      ),
    );
  }

  ProjectPauseCompositionVariantProfile? _composition(
    RuntimePlayerLayoutClass layout,
  ) {
    final composition = _presentation.composition;
    if (composition == null) return null;
    return switch (layout) {
      RuntimePlayerLayoutClass.compactPortrait => composition.compactPortrait,
      RuntimePlayerLayoutClass.compactLandscape => composition.compactLandscape,
      RuntimePlayerLayoutClass.expanded => composition.expanded,
    };
  }

  Widget _detailPane(
    BuildContext context,
    RuntimePlayerLayoutClass layout,
  ) {
    final hasDetail = widget.pauseSection != RuntimePlayerPauseSection.root;
    final controller = _detailScrollControllers.putIfAbsent(
      layout,
      () => ScrollController(
        debugLabel: 'Runtime pause detail ${layout.name}',
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (hasDetail)
              IconButton(
                key: const ValueKey<String>('runtime-pause-back-to-root'),
                tooltip: context.playerL10n.back,
                onPressed: widget.onBackToRoot,
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            Expanded(
              child: Text(
                hasDetail
                    ? widget.detailTitle ??
                        _sectionLabel(context, widget.pauseSection)
                    : _presentation.resolvedTitle(context.playerL10n),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: PlayerSpacing.sm),
        Expanded(
          child: Scrollbar(
            key: const ValueKey<String>('runtime-pause-detail-scrollbar'),
            controller: controller,
            thumbVisibility: true,
            child: SingleChildScrollView(
              key: const ValueKey<String>('runtime-pause-detail-scroll'),
              controller: controller,
              child: hasDetail
                  ? widget.detail
                  : PlayerEmptyState(
                      icon: Icons.gamepad_rounded,
                      title: _presentation.resolvedTitle(context.playerL10n),
                      message: context.playerL10n.actionUnavailable,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _rememberScrollOffsets(RuntimePlayerLayoutClass? layout) {
    if (layout == null) return;
    final navigation = _navigationScrollControllers[layout];
    if (navigation != null && navigation.hasClients) {
      _navigationScrollOffsets[layout] = navigation.offset;
    }
    final detail = _detailScrollControllers[layout];
    if (detail != null && detail.hasClients) {
      _detailScrollOffsets[layout] = detail.offset;
    }
  }

  void _restoreScrollOffsetsAfterLayout(RuntimePlayerLayoutClass layout) {
    final generation = ++_scrollRestoreGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _scrollRestoreGeneration) return;
      _restoreScrollOffset(
        _navigationScrollControllers[layout],
        _navigationScrollOffsets[layout],
      );
      _restoreScrollOffset(
        _detailScrollControllers[layout],
        _detailScrollOffsets[layout],
      );
    });
  }

  void _restoreScrollOffset(
    ScrollController? controller,
    double? offset,
  ) {
    if (controller == null ||
        offset == null ||
        !controller.hasClients ||
        !controller.position.hasContentDimensions) {
      return;
    }
    controller.jumpTo(
      offset.clamp(
        controller.position.minScrollExtent,
        controller.position.maxScrollExtent,
      ),
    );
  }

  String _sectionLabel(
    BuildContext context,
    RuntimePlayerPauseSection section,
  ) {
    final l10n = context.playerL10n;
    return switch (section) {
      RuntimePlayerPauseSection.root => _presentation.resolvedTitle(l10n),
      RuntimePlayerPauseSection.party =>
        _presentation.label(PlayerPauseAction.party, l10n),
      RuntimePlayerPauseSection.bag =>
        _presentation.label(PlayerPauseAction.bag, l10n),
      RuntimePlayerPauseSection.pokedex =>
        _presentation.label(PlayerPauseAction.pokedex, l10n),
      RuntimePlayerPauseSection.map =>
        _presentation.label(PlayerPauseAction.map, l10n),
      RuntimePlayerPauseSection.options =>
        _presentation.label(PlayerPauseAction.options, l10n),
    };
  }

  PlayerPausePresentation get _presentation =>
      widget.presentation ?? PlayerPausePresentation.fromLabels(widget.labels);

  ProjectPresentationSurfaceRole _surfaceRoleFor(
    RuntimePlayerPauseSection section,
  ) =>
      switch (section) {
        RuntimePlayerPauseSection.root =>
          ProjectPresentationSurfaceRole.pauseMenu,
        RuntimePlayerPauseSection.party => ProjectPresentationSurfaceRole.party,
        RuntimePlayerPauseSection.bag => ProjectPresentationSurfaceRole.bag,
        RuntimePlayerPauseSection.pokedex =>
          ProjectPresentationSurfaceRole.pokedex,
        RuntimePlayerPauseSection.map => ProjectPresentationSurfaceRole.map,
        RuntimePlayerPauseSection.options =>
          ProjectPresentationSurfaceRole.options,
      };
}
