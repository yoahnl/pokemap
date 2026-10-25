import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_image.dart';
import '../foundation/player_input_scope.dart';
import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'player_control_profile.dart';
import 'region_map_geometry.dart';
import 'runtime_player_actions.dart';

final class RuntimePlayerRegionMapNavigation extends ChangeNotifier {
  String? regionId;
  String? selectedPointId;
  double scale = 1;
  Offset center = const Offset(.5, .5);
  int listPage = 0;
  bool initialized = false;
  bool Function()? _back;

  bool back() => _back?.call() ?? false;

  void clearForNewSession() {
    regionId = null;
    selectedPointId = null;
    scale = 1;
    center = const Offset(.5, .5);
    listPage = 0;
    initialized = false;
    notifyListeners();
  }
}

class RuntimePlayerRegionMap extends StatefulWidget {
  const RuntimePlayerRegionMap({
    super.key,
    required this.detail,
    this.navigation,
    this.controlProfile,
    this.hardwareGamepadEnabled = true,
    this.imageProvider,
    this.onPointSelected,
  });

  final RuntimePlayerPauseDetailSnapshot detail;
  final ValueChanged<String?>? onPointSelected;
  final RuntimePlayerRegionMapNavigation? navigation;
  final PlayerControlProfile? controlProfile;
  final bool hardwareGamepadEnabled;
  final ImageProvider<Object> Function(String)? imageProvider;

  @override
  State<RuntimePlayerRegionMap> createState() => _RuntimePlayerRegionMapState();
}

class _RuntimePlayerRegionMapState extends State<RuntimePlayerRegionMap> {
  final _ownedNavigation = RuntimePlayerRegionMapNavigation();
  final _rowFocus = <String, FocusNode>{};
  final _regionChoiceFocus = <String, FocusNode>{};
  List<String> _overlap = [];
  final _overlapKey = GlobalKey();
  final _overlapFocus = FocusNode(debugLabel: 'Overlapping locations');
  final _regionBackFocus = FocusNode(debugLabel: 'Region choice back');
  final _locationsFocus = FocusNode(debugLabel: 'Map locations');
  bool _showRegions = false;
  bool _showLocations = false;
  bool _invalidated = false;
  bool _pendingPointFocus = true;
  RuntimePlayerRegionMapNavigation get _navigation =>
      widget.navigation ?? _ownedNavigation;
  List<RuntimePlayerRegionSnapshot> get _regions =>
      widget.detail.regionalMap?.regions ?? const [];
  RuntimePlayerRegionSnapshot? get _region =>
      _regions.where((region) => region.id == _navigation.regionId).firstOrNull;
  RuntimePlayerMapPointSnapshot? get _selected => _region?.points
      .where((point) => point.id == _navigation.selectedPointId)
      .firstOrNull;

  String _text(String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'fr' ? fr : en;
  bool _known(RuntimePlayerMapPointSnapshot point) =>
      point.status != RuntimePlayerMapPointStatus.unknown;
  String _label(RuntimePlayerMapPointSnapshot point) =>
      _known(point) ? point.label : '???';
  String _status(RuntimePlayerMapPointSnapshot point) => switch (point.status) {
    RuntimePlayerMapPointStatus.current => _text(
      'Vous êtes ici',
      'You are here',
    ),
    RuntimePlayerMapPointStatus.discovered => _text(
      'Lieu découvert',
      'Discovered',
    ),
    RuntimePlayerMapPointStatus.unknown => _text(
      'Non découvert',
      'Undiscovered',
    ),
  };
  IconData _icon(RuntimePlayerMapPointSnapshot point) => switch (point.status) {
    RuntimePlayerMapPointStatus.current => Icons.navigation_rounded,
    RuntimePlayerMapPointStatus.discovered => Icons.location_on_outlined,
    RuntimePlayerMapPointStatus.unknown => Icons.help_outline_rounded,
  };

  @override
  void initState() {
    super.initState();
    _attach();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _locationsFocus.requestFocus();
    });
  }

  void _attach() {
    _navigation._back = _back;
    _navigation.addListener(_reset);
    _reconcile();
  }

  void _reset() {
    if (!mounted) return;
    _pendingPointFocus = true;
    setState(() {
      _showRegions = false;
      _showLocations = false;
      _overlap = [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_navigation.initialized) setState(_reconcile);
      _rowFocus[_navigation.selectedPointId]?.requestFocus();
    });
  }

  void _reconcile() {
    if (!_navigation.initialized) {
      final region =
          _regions
              .where(
                (region) => region.points.any(
                  (point) =>
                      point.status == RuntimePlayerMapPointStatus.current,
                ),
              )
              .firstOrNull ??
          _regions.firstOrNull;
      _navigation.regionId = region?.id;
      _navigation.selectedPointId =
          region?.points
              .where(
                (point) => point.status == RuntimePlayerMapPointStatus.current,
              )
              .firstOrNull
              ?.id ??
          region?.points.firstOrNull?.id;
      _navigation.initialized = true;
      _invalidated = false;
    } else if (_region == null ||
        _selected == null && _navigation.selectedPointId != null) {
      _navigation.selectedPointId = null;
      _overlap = [];
      _invalidated = true;
      if (_region == null) {
        _navigation.regionId = _regions.firstOrNull?.id;
        _navigation.scale = 1;
        _navigation.center = const Offset(.5, .5);
      }
    }
  }

  @override
  void didUpdateWidget(RuntimePlayerRegionMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigation != widget.navigation) {
      final old = oldWidget.navigation ?? _ownedNavigation;
      old._back = null;
      old.removeListener(_reset);
      _attach();
    }
    _reconcile();
    final ids = _region?.points.map((point) => point.id).toSet() ?? <String>{};
    _overlap = _overlap.where(ids.contains).toList();
  }

  @override
  void dispose() {
    _navigation._back = null;
    _navigation.removeListener(_reset);
    _overlapFocus.dispose();
    _regionBackFocus.dispose();
    _locationsFocus.dispose();
    for (final focus in [..._rowFocus.values, ..._regionChoiceFocus.values]) {
      focus.dispose();
    }
    _ownedNavigation.dispose();
    super.dispose();
  }

  bool _back() {
    if (!_showRegions && !_showLocations && _overlap.isEmpty) return false;
    setState(() {
      _showRegions = false;
      _showLocations = false;
      _overlap = [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _locationsFocus.requestFocus();
    });
    return true;
  }

  void _openLocations() {
    _pendingPointFocus = true;
    setState(() => _showLocations = true);
  }

  void _select(
    RuntimePlayerMapPointSnapshot point, {
    bool revealRow = false,
    bool closeLocations = true,
  }) {
    _pendingPointFocus = true;
    setState(() {
      _navigation.selectedPointId = point.id;
      _invalidated = false;
      if (closeLocations) {
        _showLocations = false;
        _overlap = [];
      }
      if (point.isLocated) _navigation.center = Offset(point.u!, point.v!);
    });
    widget.onPointSelected?.call(point.id);
    if (revealRow || closeLocations) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _locationsFocus.requestFocus();
      });
    }
  }

  void _changeRegion(String? id) {
    if (id == null || id == _navigation.regionId) return;
    _pendingPointFocus = true;
    setState(() {
      _navigation.regionId = id;
      _navigation.selectedPointId = _region?.points.firstOrNull?.id;
      _navigation.scale = 1;
      _navigation.center = const Offset(.5, .5);
      _navigation.listPage = 0;
      _invalidated = false;
      _overlap = [];
    });
    widget.onPointSelected?.call(_navigation.selectedPointId);
  }

  void _openRegions() {
    setState(() {
      _showLocations = false;
      _showRegions = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _regionBackFocus.requestFocus();
    });
  }

  Object? _input(RuntimePlayerLogicalIntent intent) {
    if (intent.action == PlayerInputAction.back && _back()) return null;
    final focus = FocusManager.instance.primaryFocus;
    if (_showRegions &&
        (intent.action == PlayerInputAction.up ||
            intent.action == PlayerInputAction.down)) {
      final current = _regions.indexWhere(
        (region) => _regionChoiceFocus[region.id]?.hasFocus == true,
      );
      final next =
          (current + (intent.action == PlayerInputAction.down ? 1 : -1)).clamp(
            -1,
            _regions.length - 1,
          );
      if (next < 0) {
        _regionBackFocus.requestFocus();
      } else {
        final target = _regionChoiceFocus[_regions[next].id];
        target?.requestFocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && target?.canRequestFocus == true) {
            target!.requestFocus();
          }
        });
      }
      return null;
    }
    switch (intent.action) {
      case PlayerInputAction.up:
        focus?.previousFocus();
      case PlayerInputAction.down:
        focus?.nextFocus();
      case PlayerInputAction.left:
        focus?.focusInDirection(TraversalDirection.left);
      case PlayerInputAction.right:
        focus?.focusInDirection(TraversalDirection.right);
      case PlayerInputAction.confirm:
        if (focus?.context case final target?) {
          Actions.maybeInvoke(target, const ActivateIntent());
        }
      default:
        Actions.maybeInvoke(context, intent);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => RuntimePlayerInputBindings(
    controlProfile: widget.controlProfile,
    hardwareGamepadEnabled: widget.hardwareGamepadEnabled,
    child: Actions(
      actions: {
        RuntimePlayerLogicalIntent: CallbackAction<RuntimePlayerLogicalIntent>(
          onInvoke: _input,
        ),
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final region = _region;
          if (region == null) {
            return PlayerMenuPanel(
              child: Center(
                child: Text(
                  _text(
                    'Aucun lieu disponible dans cette région.',
                    'No locations available in this region.',
                  ),
                  style: context.playerMenuTheme.body,
                ),
              ),
            );
          }
          if (_showRegions) {
            return PlayerMenuPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlayerActionButton(
                    label: _text('Retour à la carte', 'Back to map'),
                    icon: Icons.arrow_back,
                    onPressed: _back,
                    focusNode: _regionBackFocus,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: PlayerPagedList(
                      children: [
                        for (final entry in _regions)
                          PlayerActionButton(
                            key: ValueKey('region-choice-${entry.id}'),
                            focusNode: _regionChoiceFocus.putIfAbsent(
                              entry.id,
                              () => FocusNode(debugLabel: 'Region ${entry.id}'),
                            ),
                            label: entry.label,
                            icon: Icons.map_outlined,
                            selected: entry.id == region.id,
                            onPressed: () {
                              setState(() => _showRegions = false);
                              _changeRegion(entry.id);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          final companion = PlayerCompanionScope.of(context);
          final portrait =
              constraints.maxHeight > constraints.maxWidth && !companion;
          final compact =
              portrait ||
              constraints.maxHeight < 430 ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.5;
          final sidebarWidth = companion ? 164.0 : 212.0;
          final gap = companion ? 8.0 : 16.0;
          final map = _RegionImage(
            key: ValueKey('region-image-${region.id}'),
            region: region,
            compactControls:
                (portrait
                    ? constraints.maxWidth
                    : constraints.maxWidth - gap - sidebarWidth) <
                600 * MediaQuery.textScalerOf(context).scale(1),
            navigation: _navigation,
            label: _label,
            status: _status,
            icon: _icon,
            text: _text,
            provider: widget.imageProvider,
            locationsFocus: _locationsFocus,
            onShowLocations: _openLocations,
            onSelect: (points) {
              if (points.length == 1) {
                _select(points.single, revealRow: true);
              } else {
                setState(() {
                  _overlap = points.map((point) => point.id).toList();
                  _showLocations = true;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _overlapFocus.requestFocus();
                });
              }
            },
            onChanged: () => setState(() {}),
          );
          final selector = SizedBox(
            height: 48,
            child: _regions.length > 1
                ? PlayerMenuSelectableRow(
                    key: const ValueKey('region-map-region'),
                    id: 'region-map-region',
                    label: region.label,
                    labelMaxLines: 1,
                    labelStyle: context.playerMenuTheme.label.copyWith(
                      fontSize: 12,
                    ),
                    reserveFocusMarker: false,
                    contentPadding: const EdgeInsets.all(8),
                    onPressed: _openRegions,
                  )
                : Align(
                    key: const ValueKey('region-map-region'),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      region.label,
                      style: context.playerMenuTheme.label.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ),
          );
          final detail = PlayerMenuPanel(
            key: const ValueKey('region-map-sidebar'),
            padding: EdgeInsets.all(portrait ? 12 : 8),
            child: _detail(),
          );
          final detailHeight = math.max(
            120.0,
            MediaQuery.textScalerOf(context).scale(64),
          );
          final mapHeight = math.min(
            268.0,
            math.max(32.0, constraints.maxHeight - 132 - detailHeight),
          );
          final content = portrait
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    selector,
                    const SizedBox(height: 8),
                    SizedBox(height: mapHeight + 68, child: map),
                    const SizedBox(height: 8),
                    Expanded(child: detail),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: sidebarWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          selector,
                          const SizedBox(height: 8),
                          Expanded(child: detail),
                        ],
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(child: map),
                  ],
                );
          return SizedBox.expand(
            key: const ValueKey('runtime-player-detail-map'),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ExcludeFocus(
                  excluding: _showLocations,
                  child: IgnorePointer(
                    ignoring: _showLocations,
                    child: ExcludeSemantics(
                      excluding: _showLocations,
                      child: content,
                    ),
                  ),
                ),
                if (_showLocations)
                  PlayerMenuPanel(
                    primary: true,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PlayerActionButton(
                          key: const ValueKey('region-map-locations-close'),
                          label: _text('Retour à la carte', 'Back to map'),
                          icon: Icons.arrow_back,
                          onPressed: _back,
                        ),
                        const SizedBox(height: 8),
                        Expanded(child: _listing(region, compact: compact)),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _listing(RuntimePlayerRegionSnapshot region, {required bool compact}) {
    final points = _overlap.isEmpty
        ? region.points
        : region.points.where((point) => _overlap.contains(point.id)).toList();
    return PlayerPagedList(
      key: const PageStorageKey('region-map-list'),
      sideNavigation: compact,
      initialPage: _navigation.listPage,
      onPageChanged: (value) => _navigation.listPage = value,
      onPageReady: () {
        if (!_pendingPointFocus) return;
        final node = _rowFocus[_navigation.selectedPointId];
        if (node?.context != null && node!.canRequestFocus) {
          _pendingPointFocus = false;
          node.requestFocus();
        }
      },
      revealChildKey: _overlap.isEmpty && _selected != null
          ? ValueKey('region-row-${_selected!.id}')
          : null,
      children: [
        if (_overlap.isNotEmpty) ...[
          Text(
            key: _overlapKey,
            _text('Plusieurs lieux à cet endroit', 'Several locations here'),
            style: context.playerMenuTheme.body,
          ),
          PlayerActionButton(
            label: _text('Fermer le choix', 'Close selection'),
            focusNode: _overlapFocus,
            icon: Icons.close,
            onPressed: _back,
          ),
        ],
        for (final point in points)
          PlayerMenuSelectableRow(
            key: ValueKey('region-row-${point.id}'),
            id: point.id,
            label: _label(point),
            labelMaxLines: compact ? 1 : null,
            subtitle: compact ? null : _status(point),
            semanticValue: compact ? _status(point) : null,
            minimumHeight: 60,
            leading: Icon(_icon(point)),
            selected: point.id == _navigation.selectedPointId,
            focusNode: _rowFocus.putIfAbsent(
              point.id,
              () => FocusNode(debugLabel: 'Region location'),
            ),
            onFocusChanged: (focused) {
              if (focused &&
                  !_invalidated &&
                  _navigation.selectedPointId != point.id) {
                _select(point, closeLocations: false);
              }
            },
            onPressed: () => _select(point),
          ),
      ],
    );
  }

  Widget _detail() {
    final point = _selected;
    if (point == null) {
      return PlayerPagedList(
        children: [
          Text(
            _invalidated
                ? _text(
                    'Lieu indisponible. Choisissez un autre lieu.',
                    'Location unavailable. Choose another location.',
                  )
                : _text('Sélectionnez un lieu.', 'Select a location.'),
            style: context.playerMenuTheme.body,
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = context.playerMenuTheme;
        final companion = PlayerCompanionScope.of(context);
        final titleStyle = theme.subtitle.copyWith(
          fontSize: companion ? 15 : 17,
          height: 1.2,
        );
        final bodyStyle = theme.body.copyWith(
          fontSize: companion ? 12 : 13,
          height: 1.4,
        );
        final pageHeight = math.max(32.0, constraints.maxHeight - 64);
        double textHeight(String value, TextStyle style) {
          final measure = TextPainter(
            text: TextSpan(text: value, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final height = measure.height;
          measure.dispose();
          return height;
        }

        final description = !_known(point)
            ? _text(
                'Ce lieu n’a pas encore été découvert.',
                'This location has not been discovered yet.',
              )
            : point.description ??
                  _text(
                    'Aucune description disponible.',
                    'No description available.',
                  );
        List<String> split(String value, TextStyle style) {
          final chunks = <String>[];
          var chunk = '';
          for (final word in value.split(RegExp(r'\s+'))) {
            final candidate = chunk.isEmpty ? word : '$chunk $word';
            final overflow = textHeight(candidate, style) > pageHeight;
            if (overflow && chunk.isNotEmpty) {
              chunks.add(chunk);
              chunk = word;
            } else {
              chunk = candidate;
            }
          }
          if (chunk.isNotEmpty) chunks.add(chunk);
          return chunks;
        }

        final chunks = split(description, bodyStyle);
        final title = _label(point);
        final groupedCopy =
            textHeight(title, titleStyle) +
                8 +
                textHeight(description, bodyStyle) <=
            constraints.maxHeight -
                (point.thumbnailFilePath != null || !point.isLocated ? 64 : 0);
        Widget heading(String value) => Semantics(
          header: true,
          label: '$title, ${_status(point)}',
          excludeSemantics: true,
          child: Text(value, style: titleStyle),
        );
        return KeyedSubtree(
          key: ValueKey('region-detail-${point.id}'),
          child: PlayerPagedList(
            key: ValueKey((
              'region-detail-${point.id}',
              constraints.biggest,
              MediaQuery.textScalerOf(context).scale(1),
            )),
            children: [
              if (groupedCopy)
                Column(
                  key: const ValueKey('region-detail-copy'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    heading(title),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      key: const ValueKey('region-description-0'),
                      style: bodyStyle,
                    ),
                  ],
                )
              else
                for (final part in split(title, titleStyle)) heading(part),
              if (_known(point) && point.thumbnailFilePath != null)
                PlayerFileImage(
                  path: point.thumbnailFilePath!,
                  height: math.min(100, pageHeight),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  fallback: const SizedBox.shrink(),
                ),
              if (!groupedCopy)
                for (var index = 0; index < chunks.length; index++)
                  Text(
                    chunks[index],
                    key: ValueKey('region-description-$index'),
                    style: bodyStyle,
                  ),
              if (!point.isLocated)
                Text(
                  _text('Position non renseignée.', 'Position not provided.'),
                  style: theme.meta,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RegionImage extends StatefulWidget {
  const _RegionImage({
    super.key,
    required this.region,
    required this.compactControls,
    required this.navigation,
    required this.label,
    required this.status,
    required this.icon,
    required this.text,
    required this.onSelect,
    required this.onChanged,
    required this.onShowLocations,
    required this.locationsFocus,
    this.provider,
  });
  final RuntimePlayerRegionSnapshot region;
  final bool compactControls;
  final RuntimePlayerRegionMapNavigation navigation;
  final String Function(RuntimePlayerMapPointSnapshot) label;
  final String Function(RuntimePlayerMapPointSnapshot) status;
  final IconData Function(RuntimePlayerMapPointSnapshot) icon;
  final String Function(String, String) text;
  final void Function(List<RuntimePlayerMapPointSnapshot>) onSelect;
  final VoidCallback onChanged;
  final VoidCallback onShowLocations;
  final FocusNode locationsFocus;
  final ImageProvider<Object> Function(String)? provider;
  @override
  State<_RegionImage> createState() => _RegionImageState();
}

class _RegionImageState extends State<_RegionImage> {
  PlayerImageLease? _lease;
  bool _hasSource = false;
  ImageProvider<Object>? _provider;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _imageSize;
  RegionMapGeometry? _gestureStart;
  Offset _gestureFocal = Offset.zero;
  bool _failed = false;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadImage();
  }

  @override
  void didUpdateWidget(_RegionImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.region.imageFilePath != widget.region.imageFilePath ||
        oldWidget.provider != widget.provider) {
      _loadImage();
    }
  }

  void _loadImage() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _lease?.dispose();
    _lease = null;
    final generation = ++_generation;
    _imageSize = null;
    _failed = false;
    final path = widget.region.imageFilePath;
    if (path == null) {
      _provider = null;
      _hasSource = false;
      return;
    }
    final loader = PlayerImageScope.maybeOf(context);
    if (loader != null) {
      _provider = null;
      _hasSource = true;
      unawaited(_loadLease(loader, path, generation));
      return;
    }
    _provider = widget.provider?.call(path);
    _hasSource = _provider != null;
    if (_provider == null) return;
    _stream = _provider!.resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener(
      (info, synchronous) {
        final size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        info.dispose();
        if (!mounted || generation != _generation) return;
        if (synchronous) {
          _imageSize = size;
        } else {
          setState(() => _imageSize = size);
        }
      },
      onError: (Object error, StackTrace? stack) {
        if (!mounted || generation != _generation) return;
        setState(() => _failed = true);
      },
    );
    _stream!.addListener(_listener!);
  }

  Future<void> _loadLease(
    PlayerImageLoader loader,
    String path,
    int generation,
  ) async {
    bool current() => mounted && generation == _generation;
    try {
      final lease = await loader(path, isCurrent: current);
      if (!current()) {
        lease.dispose();
        return;
      }
      setState(() {
        _lease = lease;
        _imageSize = Size(
          lease.image.width.toDouble(),
          lease.image.height.toDouble(),
        );
      });
    } on Object {
      if (current()) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    ++_generation;
    _lease?.dispose();
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  void _update(RegionMapGeometry geometry) {
    widget.navigation.scale = geometry.scale;
    widget.navigation.center = geometry.center;
    widget.onChanged();
  }

  Widget _viewport(Widget child) => Expanded(child: child);

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    return PlayerMenuPanel(
      key: const ValueKey('region-map-canvas-panel'),
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewport(
            LayoutBuilder(
              builder: (context, constraints) {
                final size = _imageSize;
                if (!_hasSource || _failed) {
                  if (constraints.maxHeight < 100) {
                    return Tooltip(
                      message: widget.text(
                        'Carte régionale indisponible.',
                        'Regional map unavailable.',
                      ),
                      child: const Center(
                        child: Icon(Icons.map_outlined, size: 24),
                      ),
                    );
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        widget.text(
                          'Carte régionale indisponible.',
                          'Regional map unavailable.',
                        ),
                        style: theme.meta,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (size == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final geometry = RegionMapGeometry(
                  viewport: constraints.biggest,
                  imageSize: size,
                  fit: BoxFit.cover,
                  scale: widget.navigation.scale,
                  center: widget.navigation.center,
                );
                void selectAt(Offset position) {
                  final normalized = geometry.unproject(position);
                  final hits = widget.region.points
                      .where(
                        (point) =>
                            point.isLocated &&
                            ((point.u! - normalized.dx) *
                                        geometry.imageRect.width *
                                        geometry.scale)
                                    .abs() <=
                                24 &&
                            ((point.v! - normalized.dy) *
                                        geometry.imageRect.height *
                                        geometry.scale)
                                    .abs() <=
                                24,
                      )
                      .toList();
                  if (hits.isNotEmpty) widget.onSelect(hits);
                }

                return Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      GestureBinding.instance.pointerSignalResolver.register(
                        event,
                        (_) => _update(
                          geometry.zoom(
                            geometry.scale *
                                math.exp(-event.scrollDelta.dy / 500),
                            event.localPosition,
                          ),
                        ),
                      );
                    }
                  },
                  child: GestureDetector(
                    key: const ValueKey('region-map-canvas'),
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) => selectAt(details.localPosition),
                    onScaleStart: (details) {
                      _gestureStart = geometry;
                      _gestureFocal = details.localFocalPoint;
                    },
                    onScaleUpdate: (details) {
                      final start = _gestureStart;
                      if (start != null) {
                        _update(
                          start
                              .zoom(start.scale * details.scale, _gestureFocal)
                              .pan(details.localFocalPoint - _gestureFocal),
                        );
                      }
                    },
                    child: ClipRect(
                      child: Stack(
                        children: [
                          Positioned.fromRect(
                            rect: geometry.transformedImageRect,
                            child: _lease != null
                                ? RawImage(
                                    image: _lease!.image,
                                    fit: BoxFit.fill,
                                    filterQuality: widget.region.pixelArt
                                        ? FilterQuality.none
                                        : FilterQuality.medium,
                                  )
                                : Image(
                                    image: _provider!,
                                    fit: BoxFit.fill,
                                    excludeFromSemantics: true,
                                    filterQuality: widget.region.pixelArt
                                        ? FilterQuality.none
                                        : FilterQuality.medium,
                                    errorBuilder: (context, error, stack) =>
                                        const SizedBox.shrink(),
                                  ),
                          ),
                          for (final point in widget.region.points.where(
                            (point) => point.isLocated,
                          ))
                            Positioned.fromRect(
                              rect: Rect.fromCenter(
                                center: geometry.project(
                                  Offset(point.u!, point.v!),
                                ),
                                width: 48,
                                height: 48,
                              ),
                              child: Semantics(
                                key: ValueKey('region-pin-${point.id}'),
                                button: true,
                                label: widget.label(point),
                                value: widget.status(point),
                                selected:
                                    widget.navigation.selectedPointId ==
                                    point.id,
                                onTap: () => widget.onSelect([point]),
                                child: ExcludeSemantics(
                                  child: IgnorePointer(
                                    child: Center(
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: theme.panel,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                widget
                                                        .navigation
                                                        .selectedPointId ==
                                                    point.id
                                                ? theme.focus
                                                : theme.border,
                                            width:
                                                widget
                                                        .navigation
                                                        .selectedPointId ==
                                                    point.id
                                                ? 3
                                                : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.shadow,
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          widget.icon(point),
                                          size: 22,
                                          color: theme.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: _controls(
              children: [
                _control(
                  key: const ValueKey('region-map-zoom-out'),
                  label: widget.text('Réduire', 'Zoom out'),
                  icon: Icons.remove,
                  onPressed:
                      _imageSize == null ||
                          _failed ||
                          widget.navigation.scale <= 1
                      ? null
                      : () {
                          widget.navigation.scale =
                              (widget.navigation.scale - .25).clamp(1, 3);
                          widget.onChanged();
                        },
                ),
                Semantics(
                  label: 'Zoom',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '${(widget.navigation.scale * 100).round()} %',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.meta,
                    ),
                  ),
                ),
                _control(
                  key: const ValueKey('region-map-zoom-in'),
                  label: widget.text('Agrandir', 'Zoom in'),
                  icon: Icons.add,
                  onPressed:
                      _imageSize == null ||
                          _failed ||
                          widget.navigation.scale >= 3
                      ? null
                      : () {
                          widget.navigation.scale =
                              (widget.navigation.scale + .25).clamp(1, 3);
                          widget.onChanged();
                        },
                ),
                _control(
                  key: const ValueKey('region-map-recenter'),
                  label: widget.text('Recentrer', 'Recenter'),
                  icon: Icons.center_focus_strong,
                  onPressed: _imageSize == null || _failed
                      ? null
                      : () {
                          widget.navigation.scale = 1;
                          widget.navigation.center = const Offset(.5, .5);
                          widget.onChanged();
                        },
                ),
                _control(
                  key: const ValueKey('region-map-locations'),
                  label: widget.text('Lieux', 'Locations'),
                  icon: Icons.list_rounded,
                  focusNode: widget.locationsFocus,
                  onPressed: widget.onShowLocations,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls({required List<Widget> children}) {
    if (!widget.compactControls) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: children,
      );
    }
    return Row(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          if (index == 1)
            Expanded(child: Center(child: children[index]))
          else
            children[index],
        ],
      ],
    );
  }

  Widget _control({
    required ValueKey<String> key,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    FocusNode? focusNode,
  }) {
    if (!widget.compactControls) {
      return PlayerActionButton(
        key: key,
        label: label,
        icon: icon,
        expandWidth: false,
        focusNode: focusNode,
        onPressed: onPressed,
      );
    }
    return Tooltip(
      message: label,
      child: SizedBox(
        width: 48,
        child: PlayerMenuSelectableRow(
          key: key,
          id: key.value,
          focusNode: focusNode,
          label: label,
          leading: Icon(icon),
          iconOnly: true,
          contentPadding: EdgeInsets.zero,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
