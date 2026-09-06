import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_layout_theme.dart';
import '../theme/pokemap_player_surface_palette_theme.dart';
import '../theme/pokemap_player_window_theme.dart';
import 'player_pause_menu.dart';
import 'player_pause_illustrated_root.dart';
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
    this.playerProfile,
    this.portraitImage,
    this.detailOwnsScroll = false,
    this.detailActions,
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
    this.playerProfile,
    this.portraitImage,
    this.detailOwnsScroll = false,
    this.detailActions,
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
  final RuntimePlayerProfileSnapshot? playerProfile;
  final ImageProvider? portraitImage;
  final bool detailOwnsScroll;
  final Widget? detailActions;

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
  ImageProvider? _failedBackgroundImage;
  final _detailReturnFocus = FocusNode(debugLabel: 'Pause detail return');

  @override
  void initState() {
    super.initState();
    _attachFocusController();
    _applyExternalFocusState();
  }

  @override
  void didUpdateWidget(covariant RuntimePlayerPauseShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation?.backgroundImage !=
        widget.presentation?.backgroundImage) {
      _failedBackgroundImage = null;
    }
    if (oldWidget.focusController != widget.focusController) {
      _detachFocusController();
      _attachFocusController();
    }
    _applyExternalFocusState(
      preferExternal: oldWidget.logicalSelectionId != widget.logicalSelectionId,
      focusDetail: oldWidget.pauseSection != widget.pauseSection,
    );
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

  void _applyExternalFocusState(
      {bool preferExternal = false, bool focusDetail = true}) {
    if (widget.activeInputSource case final source?) {
      _focusController.noteInputSource(source);
    }
    if (_isIllustrated &&
        widget.pauseSection != RuntimePlayerPauseSection.root) {
      if (focusDetail) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _focusController.showFocusHighlight) {
            _detailReturnFocus.requestFocus();
          }
        });
      }
      return;
    }
    _focusController.restoreSelection(
      _availableSelectionId(preferExternal
          ? widget.logicalSelectionId
          : _focusController.logicalSelectionId ?? widget.logicalSelectionId),
    );
  }

  String? _availableSelectionId(String? preferred) {
    final visible = _presentation.visibleActions;
    final availableSelectionIds = [
      ...visible.where((action) =>
          !_isIllustrated ||
          action != PlayerPauseAction.resume &&
              (action != PlayerPauseAction.returnToTitle ||
                  !_returnToTitleInOptions)),
      if (_isIllustrated) PlayerPauseAction.resume,
    ]
        .where((action) => widget.actions[action]?.isEnabled == true)
        .map((action) => 'pause.${action.name}')
        .toList(growable: false);
    if (availableSelectionIds.contains(preferred)) return preferred;
    final current = _focusController.logicalSelectionId;
    if (availableSelectionIds.contains(current)) return current;
    if (preferred == null &&
        current == null &&
        (!_isIllustrated || !_focusController.showFocusHighlight)) {
      return null;
    }
    return availableSelectionIds.firstOrNull;
  }

  void _onFocusStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _rememberScrollOffsets(_lastLayout);
    _detailReturnFocus.dispose();
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
          builder: (context) => widget.presentation?.style ==
                  ProjectPauseMenuStyle.nightIllustrated
              ? PlayerMenuThemeScope(
                  child: Builder(builder: _buildIllustratedFrame))
              : PlayerPauseSurface.composed(child: _buildSurface(context)),
        ),
      );

  bool get _isIllustrated =>
      widget.presentation?.style == ProjectPauseMenuStyle.nightIllustrated;

  bool get _returnToTitleInOptions =>
      _isIllustrated &&
      _presentation.actionOrder == null &&
      _presentation.visibleActions.contains(PlayerPauseAction.options) &&
      widget.actions[PlayerPauseAction.options]?.isEnabled == true;

  RuntimePlayerLayoutClass _layoutClass(
    BoxConstraints constraints,
    ProjectResolvedSurfaceLayout? resolved,
  ) =>
      resolved == null
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

  Widget _buildIllustratedFrame(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final resolved = context.playerLayoutTheme?.resolve(
            ProjectPresentationSurfaceRole.pauseMenu,
            constraints,
          );
          final layout = _layoutClass(constraints, resolved);
          final tokens = context.playerMenuTheme;
          final presentation = widget.presentation!;
          final image = presentation.backgroundImage;
          final background = presentation.background;
          final isRoot = widget.pauseSection == RuntimePlayerPauseSection.root;
          final resume = widget.actions[PlayerPauseAction.resume] ??
              PlayerActionAvailability.disabled(
                  context.playerL10n.actionUnavailable);
          final returnLabel = isRoot
              ? presentation.actionLabels[PlayerPauseAction.resume] ??
                  widget.labels.resume ??
                  context.playerL10n.resume
              : context.playerL10n.back;
          final unavailable = background != null &&
              (image == null || _failedBackgroundImage == image);
          final fallback = DecoratedBox(
            key: const ValueKey('runtime-menu-background-fallback'),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tokens.backdrop, tokens.base],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          );
          final pixelRatio = MediaQuery.devicePixelRatioOf(context);
          final decodeWidth =
              (constraints.maxWidth * pixelRatio).ceil().clamp(1, 1920);
          final decodeHeight =
              (constraints.maxHeight * pixelRatio).ceil().clamp(1, 1080);
          final artwork = image == null
              ? fallback
              : KeyedSubtree(
                  key: ValueKey(image),
                  child: Image(
                    key: const ValueKey('runtime-menu-background'),
                    image: ResizeImage(image,
                        width: decodeWidth,
                        height: decodeHeight,
                        policy: ResizeImagePolicy.fit),
                    fit: BoxFit.cover,
                    alignment: Alignment((background?.focalX ?? .5) * 2 - 1,
                        (background?.focalY ?? .5) * 2 - 1),
                    filterQuality: background?.sampling ==
                            ProjectMenuImageSampling.pixelArt
                        ? FilterQuality.none
                        : FilterQuality.medium,
                    errorBuilder: (_, error, stack) {
                      if (_failedBackgroundImage != image) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted &&
                              widget.presentation?.backgroundImage == image &&
                              _failedBackgroundImage != image) {
                            setState(() => _failedBackgroundImage = image);
                          }
                        });
                      }
                      return fallback;
                    },
                  ),
                );
          return RuntimePlayerActions(
            onBack: widget.onBackToRoot,
            onMenu: widget.onTouchMenu ?? widget.onBackToRoot,
            onInputSourceChanged: _focusController.noteInputSource,
            child: PlayerMenuFrame(
              key: const ValueKey('runtime-night-illustrated-frame'),
              scrollable: false,
              backdrop: isRoot ? null : artwork,
              contentPadding: isRoot ? EdgeInsets.zero : null,
              header: isRoot || _composition(layout)?.showTitle == false
                  ? const SizedBox.shrink()
                  : PlayerMenuHeader(
                      icon: Icons.menu,
                      title: isRoot
                          ? presentation.title ?? widget.gameTitle
                          : widget.detailTitle ??
                              _sectionLabel(context, widget.pauseSection)),
              footer: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (unavailable)
                    Semantics(
                      key:
                          const ValueKey('runtime-menu-background-unavailable'),
                      liveRegion: true,
                      child: Text(context.playerL10n.menuBackgroundUnavailable,
                          style: tokens.meta),
                    ),
                  PlayerMenuFooter(
                    alignReturnEnd: true,
                    hintsFlex: !isRoot && widget.detailActions != null
                        ? (layout == RuntimePlayerLayoutClass.compactPortrait
                            ? 3
                            : 4)
                        : 1,
                    hints: [
                      if (!isRoot && widget.detailActions != null)
                        widget.detailActions!,
                      if (_focusController.showFocusHighlight && isRoot)
                        PlayerMenuKeyHint(
                            glyph: _focusController.activeInputSource ==
                                    PlayerInputSource.controller
                                ? 'A'
                                : context.playerL10n.confirmShortcut,
                            label: context.playerL10n.validate),
                    ],
                    returnAction: PlayerMenuSelectableRow(
                      id: 'pause-frame-return',
                      label: returnLabel,
                      leading: const Icon(Icons.arrow_back),
                      integrated: true,
                      showFocusHighlight: _focusController.showFocusHighlight,
                      focusNode: isRoot
                          ? _focusController.nodeFor('pause.resume',
                              debugLabel: 'Player action: $returnLabel')
                          : _detailReturnFocus,
                      selected: isRoot &&
                          _focusController.logicalSelectionId == 'pause.resume',
                      disabledReason: isRoot ? resume.disabledReason : null,
                      onPressed: isRoot && !resume.isEnabled
                          ? null
                          : () {
                              if (isRoot) {
                                _focusController.select('pause.resume');
                                widget.onSelected(PlayerPauseAction.resume);
                              } else {
                                widget.onBackToRoot();
                              }
                            },
                    ),
                  ),
                ],
              ),
              child: _buildSurface(context,
                  layoutOverride: layout,
                  resolvedOverride: resolved,
                  illustratedBackground: isRoot ? artwork : null),
            ),
          );
        },
      );

  Widget _buildSurface(
    BuildContext context, {
    RuntimePlayerLayoutClass? layoutOverride,
    ProjectResolvedSurfaceLayout? resolvedOverride,
    Widget? illustratedBackground,
  }) {
    return _surfaceActions(
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
            color: widget.presentation?.style ==
                    ProjectPauseMenuStyle.nightIllustrated
                ? context.playerMenuTheme.base.withValues(alpha: 0)
                : context.playerPauseBackdropColor,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final resolved = layoutOverride == null
                      ? context.playerLayoutTheme?.resolve(
                          ProjectPresentationSurfaceRole.pauseMenu, constraints)
                      : resolvedOverride;
                  final layout =
                      layoutOverride ?? _layoutClass(constraints, resolved);
                  if (_lastLayout != layout) {
                    _rememberScrollOffsets(_lastLayout);
                    _lastLayout = layout;
                    if (!_isIllustrated ||
                        widget.pauseSection == RuntimePlayerPauseSection.root) {
                      _focusController.restoreSelection(
                        _availableSelectionId(
                          _focusController.logicalSelectionId ??
                              widget.logicalSelectionId,
                        ),
                      );
                    }
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
                      if (_isIllustrated)
                        if (widget.pauseSection ==
                            RuntimePlayerPauseSection.root)
                          PlayerPauseIllustratedRoot(
                            gameTitle: widget.gameTitle,
                            menuTitle:
                                _presentation.title ?? context.playerL10n.menu,
                            showTitle: composition?.showTitle ?? true,
                            showGameTitle: resolved
                                    ?.variant.visibleSecondaryElements
                                    .contains(
                                        ProjectPresentationSecondaryElement
                                            .pauseGameTitle) ??
                                false,
                            hint: composition?.showHint == false
                                ? null
                                : _presentation.hint,
                            profile: widget.playerProfile,
                            portraitImage: widget.portraitImage,
                            showSummary:
                                composition?.showRootDetailPanel ?? true,
                            extraDetail: widget.playerProfile == null
                                ? widget.detail
                                : null,
                            background: illustratedBackground!,
                            navigation: _navigation(layout,
                                resolved: resolved,
                                composition: composition,
                                scrollKey: const ValueKey(
                                    'runtime-pause-navigation-scroll')),
                          )
                        else
                          _detailPane(context, layout)
                      else
                        switch (layout) {
                          RuntimePlayerLayoutClass.compactPortrait =>
                            _compactPortrait(
                              context,
                              layout,
                              resolved,
                              composition,
                            ),
                          RuntimePlayerLayoutClass.compactLandscape =>
                            _twoColumn(
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
                      if (!_isIllustrated &&
                          layout != RuntimePlayerLayoutClass.expanded &&
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

  Widget _surfaceActions({required Widget child}) => _isIllustrated
      ? child
      : RuntimePlayerActions(
          onBack: widget.onBackToRoot,
          onMenu: widget.onTouchMenu ?? widget.onBackToRoot,
          onInputSourceChanged: _focusController.noteInputSource,
          child: child,
        );

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
    final margin =
        _isIllustrated ? 0.0 : resolved?.additionalSafeAreaPadding ?? 0;
    return Align(
      alignment: fullScreen ? Alignment.center : Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: _isIllustrated || fullScreen ? 1 : .86,
        widthFactor: _isIllustrated ? 1 : resolved?.maxWidthFactor ?? 1,
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
    final effectiveWidthFactor =
        _isIllustrated ? null : resolved?.maxWidthFactor ?? widthFactor;
    final margin = _isIllustrated
        ? 0.0
        : resolved?.additionalSafeAreaPadding ?? PlayerSpacing.md;
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
        maxWidth: _isIllustrated || effectiveWidthFactor != null
            ? double.infinity
            : 820,
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
      () {
        final controller = ScrollController(
          debugLabel: 'Runtime pause navigation ${layout.name}',
          initialScrollOffset:
              _focusController.navigationScrollOffsets[layout.name] ?? 0,
        );
        controller.addListener(() {
          if (!controller.hasClients) return;
          _navigationScrollOffsets[layout] = controller.offset;
          _focusController.navigationScrollOffsets[layout.name] =
              controller.offset;
        });
        return controller;
      },
    );
    return Scrollbar(
      key: const ValueKey<String>('runtime-pause-navigation-scrollbar'),
      controller: controller,
      thumbVisibility: true,
      child: PlayerPauseNavigation(
        illustrated: _isIllustrated,
        gameTitle: widget.gameTitle,
        actions: widget.actions,
        onSelected: widget.onSelected,
        scrollKey: scrollKey,
        scrollController: controller,
        focusController: _focusController,
        labels: widget.labels,
        presentation: _isIllustrated
            ? PlayerPausePresentation(
                title: _presentation.title,
                hint: _presentation.hint,
                actionOrder: _presentation.actionOrder,
                actionLabels: {
                  PlayerPauseAction.party: context.playerL10n.pokemon,
                  ..._presentation.actionLabels,
                },
                actionIcons: _presentation.actionIcons,
                hiddenActions: {
                  ..._presentation.hiddenActions,
                  PlayerPauseAction.resume,
                  if (_returnToTitleInOptions) PlayerPauseAction.returnToTitle
                },
              )
            : widget.presentation,
        showGameTitle: !_isIllustrated &&
            (resolved == null ||
                resolved.variant.visibleSecondaryElements.contains(
                  ProjectPresentationSecondaryElement.pauseGameTitle,
                )),
        composition: _isIllustrated
            ? (composition ?? const ProjectPauseCompositionVariantProfile())
                .copyWith(showTitle: false, showHint: false)
            : composition,
        compositionLayoutName: layout.name,
      ),
    );
  }

  ProjectPauseCompositionVariantProfile? _composition(
    RuntimePlayerLayoutClass layout,
  ) {
    final composition = _presentation.composition;
    if (composition == null) {
      return _isIllustrated
          ? const ProjectPauseCompositionVariantProfile()
          : null;
    }
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
    if (widget.detailOwnsScroll) {
      if (!_isIllustrated && widget.detailActions != null) {
        return LayoutBuilder(builder: (context, constraints) {
          final actions = Padding(
            padding: const EdgeInsets.only(top: PlayerSpacing.xs),
            child: widget.detailActions!,
          );
          if (!constraints.hasBoundedHeight) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [widget.detail, actions],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: widget.detail),
              ConstrainedBox(
                constraints:
                    BoxConstraints(maxHeight: constraints.maxHeight * .3),
                child: SingleChildScrollView(child: actions),
              ),
            ],
          );
        });
      }
      return widget.detail;
    }
    final controller = _detailScrollControllers.putIfAbsent(
      layout,
      () => ScrollController(
        debugLabel: 'Runtime pause detail ${layout.name}',
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!_isIllustrated)
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
        if (!_isIllustrated) const SizedBox(height: PlayerSpacing.sm),
        Expanded(
          child: Scrollbar(
            key: const ValueKey<String>('runtime-pause-detail-scrollbar'),
            controller: controller,
            thumbVisibility: true,
            child: SingleChildScrollView(
              key: const ValueKey<String>('runtime-pause-detail-scroll'),
              controller: controller,
              child: hasDetail || _isIllustrated
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        widget.detail,
                        if (_isIllustrated &&
                            widget.pauseSection ==
                                RuntimePlayerPauseSection.options &&
                            !_presentation.hiddenActions
                                .contains(PlayerPauseAction.returnToTitle))
                          PlayerMenuSelectableRow(
                            id: 'pause-options-return-to-title',
                            label: _presentation.label(
                                PlayerPauseAction.returnToTitle,
                                context.playerL10n),
                            leading: const Icon(Icons.exit_to_app_rounded),
                            disabledReason: widget
                                .actions[PlayerPauseAction.returnToTitle]
                                ?.disabledReason,
                            onPressed:
                                widget.actions[PlayerPauseAction.returnToTitle]
                                            ?.isEnabled ==
                                        true
                                    ? () => widget.onSelected(
                                        PlayerPauseAction.returnToTitle)
                                    : null,
                          ),
                      ],
                    )
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
      _focusController.navigationScrollOffsets[layout.name] = navigation.offset;
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
      RuntimePlayerPauseSection.quests =>
        _presentation.label(PlayerPauseAction.quests, l10n),
      RuntimePlayerPauseSection.profile =>
        _presentation.label(PlayerPauseAction.profile, l10n),
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
        RuntimePlayerPauseSection.quests =>
          ProjectPresentationSurfaceRole.pauseMenu,
        RuntimePlayerPauseSection.profile =>
          ProjectPresentationSurfaceRole.pauseMenu,
        RuntimePlayerPauseSection.options =>
          ProjectPresentationSurfaceRole.options,
      };
}
