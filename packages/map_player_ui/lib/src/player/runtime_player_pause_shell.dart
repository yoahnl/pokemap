import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
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
    this.labels = const PlayerPauseMenuLabels(),
  });

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
  final PlayerPauseMenuLabels labels;

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
    _focusController.restoreSelection(widget.logicalSelectionId);
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
  Widget build(BuildContext context) {
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
            color: context.playerColors.scrim,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layout = classifyRuntimePlayerLayout(constraints);
                  if (_lastLayout != layout) {
                    _rememberScrollOffsets(_lastLayout);
                    _lastLayout = layout;
                    _focusController.restoreSelection(
                      widget.logicalSelectionId ??
                          _focusController.logicalSelectionId,
                    );
                    _restoreScrollOffsetsAfterLayout(layout);
                  }
                  return Stack(
                    key: ValueKey<String>(
                      'runtime-pause-layout-${layout.name}',
                    ),
                    fit: StackFit.expand,
                    children: <Widget>[
                      switch (layout) {
                        RuntimePlayerLayoutClass.compactPortrait =>
                          _compactPortrait(context, layout),
                        RuntimePlayerLayoutClass.compactLandscape => _twoColumn(
                            context,
                            layout: layout,
                            widthFactor: .78,
                            navigationWidth: 220,
                          ),
                        RuntimePlayerLayoutClass.expanded => _twoColumn(
                            context,
                            layout: layout,
                            widthFactor: null,
                            navigationWidth: 280,
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
  ) {
    if (widget.pauseSection != RuntimePlayerPauseSection.root) {
      return PlayerPanel(
        role: PlayerPanelRole.menu,
        padding: const EdgeInsets.all(PlayerSpacing.md),
        child: _detailPane(context, layout),
      );
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: .86,
        widthFactor: 1,
        child: PlayerPanel(
          role: PlayerPanelRole.menu,
          padding: const EdgeInsets.all(PlayerSpacing.md),
          elevated: true,
          child: _navigation(layout),
        ),
      ),
    );
  }

  Widget _twoColumn(
    BuildContext context, {
    required RuntimePlayerLayoutClass layout,
    required double? widthFactor,
    required double navigationWidth,
  }) {
    Widget panel = ConstrainedBox(
      key: widthFactor == null
          ? const ValueKey<String>('runtime-pause-expanded-panel')
          : null,
      constraints: BoxConstraints(
        maxWidth: widthFactor == null ? 820 : double.infinity,
      ),
      child: PlayerPanel(
        role: PlayerPanelRole.menu,
        padding: const EdgeInsets.all(PlayerSpacing.md),
        elevated: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: navigationWidth,
              child: _navigation(
                layout,
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
    if (widthFactor != null) {
      panel = FractionallySizedBox(
        widthFactor: widthFactor,
        child: panel,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(PlayerSpacing.md),
      child: Align(
        alignment: Alignment.centerRight,
        child: panel,
      ),
    );
  }

  Widget _navigation(
    RuntimePlayerLayoutClass layout, {
    Key? scrollKey,
  }) {
    return PlayerPauseNavigation(
      gameTitle: widget.gameTitle,
      actions: widget.actions,
      onSelected: widget.onSelected,
      scrollKey: scrollKey,
      scrollController: _navigationScrollControllers.putIfAbsent(
        layout,
        () => ScrollController(
          debugLabel: 'Runtime pause navigation ${layout.name}',
        ),
      ),
      focusController: _focusController,
      labels: widget.labels,
    );
  }

  Widget _detailPane(
    BuildContext context,
    RuntimePlayerLayoutClass layout,
  ) {
    final hasDetail = widget.pauseSection != RuntimePlayerPauseSection.root;
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
                    ? _sectionLabel(context, widget.pauseSection)
                    : widget.labels.title(context.playerL10n),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: PlayerSpacing.sm),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey<String>('runtime-pause-detail-scroll'),
            controller: _detailScrollControllers.putIfAbsent(
              layout,
              () => ScrollController(
                debugLabel: 'Runtime pause detail ${layout.name}',
              ),
            ),
            child: hasDetail
                ? widget.detail
                : PlayerEmptyState(
                    icon: Icons.gamepad_rounded,
                    title: widget.labels.title(context.playerL10n),
                    message: context.playerL10n.actionUnavailable,
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
      RuntimePlayerPauseSection.root => widget.labels.title(l10n),
      RuntimePlayerPauseSection.party =>
        widget.labels.action(PlayerPauseAction.party, l10n),
      RuntimePlayerPauseSection.bag =>
        widget.labels.action(PlayerPauseAction.bag, l10n),
      RuntimePlayerPauseSection.pokedex =>
        widget.labels.action(PlayerPauseAction.pokedex, l10n),
      RuntimePlayerPauseSection.map =>
        widget.labels.action(PlayerPauseAction.map, l10n),
      RuntimePlayerPauseSection.options =>
        widget.labels.action(PlayerPauseAction.options, l10n),
    };
  }
}
