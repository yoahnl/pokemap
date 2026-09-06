import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'player_control_profile.dart';
import 'region_map_geometry.dart';
import 'runtime_player_actions.dart';

final class RuntimePlayerRegionMapNavigation extends ChangeNotifier {
  String? regionId;
  String? selectedPointId;
  double scale = 1;
  Offset center = const Offset(.5, .5);
  double listOffset = 0;
  double compactOffset = 0;
  bool initialized = false;
  bool Function()? _back;

  bool back() => _back?.call() ?? false;

  void clearForNewSession() {
    regionId = null;
    selectedPointId = null;
    scale = 1;
    center = const Offset(.5, .5);
    listOffset = 0;
    compactOffset = 0;
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
  });

  final RuntimePlayerPauseDetailSnapshot detail;
  final RuntimePlayerRegionMapNavigation? navigation;
  final PlayerControlProfile? controlProfile;
  final bool hardwareGamepadEnabled;
  final ImageProvider<Object> Function(String)? imageProvider;

  @override
  State<RuntimePlayerRegionMap> createState() => _RuntimePlayerRegionMapState();
}

class _RuntimePlayerRegionMapState extends State<RuntimePlayerRegionMap> {
  final _ownedNavigation = RuntimePlayerRegionMapNavigation();
  late ScrollController _listScroll;
  late ScrollController _compactScroll;
  var _scrollStorage = PageStorageBucket();
  final _rowKeys = <String, GlobalKey>{};
  final _rowFocus = <String, FocusNode>{};
  List<String> _overlap = [];
  final _overlapKey = GlobalKey();
  final _overlapFocus = FocusNode(debugLabel: 'Overlapping locations');
  final _regionBackFocus = FocusNode(debugLabel: 'Region choice back');
  final _infoBackFocus = FocusNode(debugLabel: 'Region info back');
  bool _showRegions = false;
  bool _showInfo = false;
  bool _invalidated = false;
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
        RuntimePlayerMapPointStatus.current =>
          _text('Vous êtes ici', 'You are here'),
        RuntimePlayerMapPointStatus.discovered =>
          _text('Lieu découvert', 'Discovered'),
        RuntimePlayerMapPointStatus.unknown =>
          _text('Non découvert', 'Undiscovered'),
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
    _listScroll = ScrollController(initialScrollOffset: _navigation.listOffset)
      ..addListener(_rememberScroll);
    _compactScroll =
        ScrollController(initialScrollOffset: _navigation.compactOffset)
          ..addListener(_rememberScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rowFocus[_navigation.selectedPointId]?.requestFocus();
    });
  }

  void _attach() {
    _navigation._back = _back;
    _navigation.addListener(_reset);
    _reconcile();
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      _showInfo = false;
      _showRegions = false;
      _overlap = [];
      _scrollStorage = PageStorageBucket();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_navigation.initialized) setState(_reconcile);
      if (_listScroll.hasClients) _listScroll.jumpTo(0);
      if (_compactScroll.hasClients) _compactScroll.jumpTo(0);
      _rowFocus[_navigation.selectedPointId]?.requestFocus();
    });
  }

  void _reconcile() {
    if (!_navigation.initialized) {
      final region = _regions
              .where((region) => region.points.any((point) =>
                  point.status == RuntimePlayerMapPointStatus.current))
              .firstOrNull ??
          _regions.firstOrNull;
      _navigation.regionId = region?.id;
      _navigation.selectedPointId = region?.points
              .where((point) =>
                  point.status == RuntimePlayerMapPointStatus.current)
              .firstOrNull
              ?.id ??
          region?.points.firstOrNull?.id;
      _navigation.initialized = true;
      _invalidated = false;
    } else if (_region == null ||
        _selected == null && _navigation.selectedPointId != null) {
      _navigation.selectedPointId = null;
      _showInfo = false;
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

  void _rememberScroll() {
    if (_listScroll.hasClients) _navigation.listOffset = _listScroll.offset;
    if (_compactScroll.hasClients) {
      _navigation.compactOffset = _compactScroll.offset;
    }
  }

  @override
  void dispose() {
    _navigation._back = null;
    _navigation.removeListener(_reset);
    _listScroll.dispose();
    _compactScroll.dispose();
    _overlapFocus.dispose();
    _regionBackFocus.dispose();
    _infoBackFocus.dispose();
    for (final focus in _rowFocus.values) {
      focus.dispose();
    }
    _ownedNavigation.dispose();
    super.dispose();
  }

  bool _back() {
    if (!_showInfo && !_showRegions && _overlap.isEmpty) return false;
    setState(() {
      _showInfo = false;
      _showRegions = false;
      _overlap = [];
    });
    _rowFocus[_navigation.selectedPointId]?.requestFocus();
    return true;
  }

  void _select(RuntimePlayerMapPointSnapshot point, {bool revealRow = false}) {
    setState(() {
      _navigation.selectedPointId = point.id;
      _invalidated = false;
      _overlap = [];
      if (point.isLocated) _navigation.center = Offset(point.u!, point.v!);
    });
    if (revealRow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _rowFocus[point.id]?.requestFocus();
        final rowContext = _rowKeys[point.id]?.currentContext;
        if (rowContext != null) {
          Scrollable.ensureVisible(rowContext, alignment: .5);
        }
      });
    }
  }

  void _changeRegion(String? id) {
    if (id == null || id == _navigation.regionId) return;
    setState(() {
      _navigation.regionId = id;
      _navigation.selectedPointId = _region?.points.firstOrNull?.id;
      _navigation.scale = 1;
      _navigation.center = const Offset(.5, .5);
      _navigation.listOffset = 0;
      _navigation.compactOffset = 0;
      _scrollStorage = PageStorageBucket();
      _invalidated = false;
      _showInfo = false;
      _overlap = [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_listScroll.hasClients) _listScroll.jumpTo(0);
      if (_compactScroll.hasClients) _compactScroll.jumpTo(0);
    });
  }

  void _openRegions() {
    setState(() => _showRegions = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _regionBackFocus.requestFocus();
    });
  }

  void _openInfo() {
    setState(() => _showInfo = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _infoBackFocus.requestFocus();
    });
  }

  Object? _input(RuntimePlayerLogicalIntent intent) {
    if (intent.action == PlayerInputAction.back && _back()) return null;
    final focus = FocusManager.instance.primaryFocus;
    switch (intent.action) {
      case PlayerInputAction.up:
        focus?.focusInDirection(TraversalDirection.up);
      case PlayerInputAction.down:
        focus?.focusInDirection(TraversalDirection.down);
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
  Widget build(BuildContext context) {
    final region = _region;
    final theme = context.playerMenuTheme;
    return PageStorage(
        bucket: _scrollStorage,
        child: RuntimePlayerInputBindings(
          controlProfile: widget.controlProfile,
          hardwareGamepadEnabled: widget.hardwareGamepadEnabled,
          child: Actions(
            actions: {
              RuntimePlayerLogicalIntent:
                  CallbackAction<RuntimePlayerLogicalIntent>(onInvoke: _input)
            },
            child: LayoutBuilder(builder: (context, constraints) {
              if (region == null) {
                return PlayerMenuPanel(
                    child: Center(
                        child: Text(
                            _text('Aucun lieu disponible dans cette région.',
                                'No locations available in this region.'),
                            style: theme.body)));
              }
              if (_showInfo && _selected != null) {
                final point = _selected!;
                return PlayerMenuPanel(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      PlayerActionButton(
                          label: _text('Retour à la carte', 'Back to map'),
                          icon: Icons.arrow_back,
                          onPressed: _back,
                          focusNode: _infoBackFocus,
                          autofocus: true),
                      const SizedBox(height: 16),
                      Expanded(
                          child: SingleChildScrollView(
                              child: _information(point))),
                    ]));
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
                          autofocus: true),
                      const SizedBox(height: 16),
                      Expanded(
                          child: SingleChildScrollView(
                              child: Column(children: [
                        for (final entry in _regions)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: PlayerActionButton(
                                  key: ValueKey('region-choice-${entry.id}'),
                                  label: entry.label,
                                  icon: Icons.map_outlined,
                                  selected: entry.id == region.id,
                                  onPressed: () {
                                    setState(() => _showRegions = false);
                                    _changeRegion(entry.id);
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted) {
                                        _rowFocus[_navigation.selectedPointId]
                                            ?.requestFocus();
                                      }
                                    });
                                  })),
                      ]))),
                    ]));
              }
              final compact = constraints.maxWidth < 840 ||
                  constraints.maxHeight < 430 ||
                  MediaQuery.textScalerOf(context).scale(1) >= 1.5;
              final map = _RegionImage(
                key: ValueKey('region-image-${region.id}'),
                region: region,
                navigation: _navigation,
                label: _label,
                status: _status,
                icon: _icon,
                text: _text,
                provider: widget.imageProvider,
                canvasHeight:
                    compact ? math.max(200, constraints.maxWidth * .5) : null,
                onSelect: (points) {
                  if (points.length == 1) {
                    _select(points.single, revealRow: true);
                  } else {
                    setState(() =>
                        _overlap = points.map((point) => point.id).toList());
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _overlapFocus.requestFocus();
                      final target = _overlapKey.currentContext;
                      if (target != null) Scrollable.ensureVisible(target);
                    });
                  }
                },
                onChanged: () => setState(() {}),
              );
              final side = PlayerMenuPanel(
                key: const ValueKey('region-map-sidebar'),
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_regions.length > 1)
                        PlayerActionButton(
                            key: const ValueKey('region-map-region'),
                            label: region.label,
                            icon: Icons.unfold_more,
                            onPressed: _openRegions)
                      else
                        Text(region.label, style: theme.subtitle),
                      const SizedBox(height: 12),
                      if (_overlap.isNotEmpty) ...[
                        Text(
                            key: _overlapKey,
                            _text('Plusieurs lieux à cet endroit',
                                'Several locations here'),
                            style: theme.body),
                        PlayerActionButton(
                            label: _text('Fermer le choix', 'Close selection'),
                            focusNode: _overlapFocus,
                            icon: Icons.close,
                            onPressed: _back),
                      ],
                      if (compact)
                        _listing(region, compact: true)
                      else
                        Expanded(
                            flex: 5, child: _listing(region, compact: false)),
                      const SizedBox(height: 12),
                      if (compact)
                        _detail()
                      else
                        Expanded(
                            flex: 4,
                            child: SingleChildScrollView(child: _detail())),
                    ]),
              );
              return SizedBox.expand(
                  key: const ValueKey('runtime-player-detail-map'),
                  child: compact
                      ? SingleChildScrollView(
                          key: const PageStorageKey('region-map-scroll'),
                          controller: _compactScroll,
                          child: Column(children: [
                            map,
                            const SizedBox(height: 16),
                            side
                          ]))
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                              Expanded(child: map),
                              const SizedBox(width: 24),
                              SizedBox(
                                  width:
                                      math.min(384, constraints.maxWidth * .36),
                                  child: side)
                            ]));
            }),
          ),
        ));
  }

  Widget _listing(RuntimePlayerRegionSnapshot region, {required bool compact}) {
    final points = _overlap.isEmpty
        ? region.points
        : region.points.where((point) => _overlap.contains(point.id)).toList();
    return SingleChildScrollView(
      key: const PageStorageKey('region-map-list'),
      controller: compact ? null : _listScroll,
      physics: compact ? const NeverScrollableScrollPhysics() : null,
      child: Column(
          children: points.map((point) {
        final focus = _rowFocus.putIfAbsent(
            point.id, () => FocusNode(debugLabel: 'Region location'));
        return Padding(
          key: _rowKeys.putIfAbsent(point.id, GlobalKey.new),
          padding: const EdgeInsets.only(bottom: 4),
          child: PlayerMenuSelectableRow(
            key: ValueKey('region-row-${point.id}'),
            id: point.id,
            label: _label(point),
            subtitle: _status(point),
            minimumHeight: 60,
            leading: Icon(_icon(point),
                color: point.id == _navigation.selectedPointId
                    ? context.playerMenuTheme.selectionText
                    : context.playerMenuTheme.accent),
            selected: point.id == _navigation.selectedPointId,
            focusNode: focus,
            onFocusChanged: (focused) {
              if (focused && _navigation.selectedPointId != point.id) {
                _select(point);
              }
            },
            onPressed: () => _select(point),
          ),
        );
      }).toList()),
    );
  }

  Widget _detail() {
    final point = _selected;
    if (point == null) {
      return Text(
          _invalidated
              ? _text('Lieu indisponible. Choisissez un autre lieu.',
                  'Location unavailable. Choose another location.')
              : _text('Sélectionnez un lieu.', 'Select a location.'),
          style: context.playerMenuTheme.body);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _information(point),
      const SizedBox(height: 12),
      PlayerActionButton(
          key: const ValueKey('region-map-info'),
          label: _text('Infos', 'Info'),
          icon: Icons.info_outline,
          onPressed: _openInfo),
    ]);
  }

  Widget _information(RuntimePlayerMapPointSnapshot point) {
    final theme = context.playerMenuTheme;
    final path = _known(point) ? point.thumbnailFilePath : null;
    return Column(
        key: ValueKey('region-detail-${point.id}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (path != null) ...[
            Image(
                image:
                    widget.imageProvider?.call(path) ?? FileImage(File(path)),
                height: 100,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink()),
            const SizedBox(height: 12),
          ],
          Text(_label(point), style: theme.subtitle),
          const SizedBox(height: 4),
          Text(_status(point), style: theme.meta),
          const SizedBox(height: 8),
          Text(
              !_known(point)
                  ? _text('Ce lieu n’a pas encore été découvert.',
                      'This location has not been discovered yet.')
                  : point.description ??
                      _text('Aucune description disponible.',
                          'No description available.'),
              style: theme.body),
          if (!point.isLocated)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    _text('Position non renseignée.', 'Position not provided.'),
                    style: theme.meta)),
        ]);
  }
}

class _RegionImage extends StatefulWidget {
  const _RegionImage(
      {super.key,
      required this.region,
      required this.navigation,
      required this.label,
      required this.status,
      required this.icon,
      required this.text,
      required this.onSelect,
      required this.onChanged,
      this.canvasHeight,
      this.provider});
  final RuntimePlayerRegionSnapshot region;
  final RuntimePlayerRegionMapNavigation navigation;
  final String Function(RuntimePlayerMapPointSnapshot) label;
  final String Function(RuntimePlayerMapPointSnapshot) status;
  final IconData Function(RuntimePlayerMapPointSnapshot) icon;
  final String Function(String, String) text;
  final void Function(List<RuntimePlayerMapPointSnapshot>) onSelect;
  final VoidCallback onChanged;
  final double? canvasHeight;
  final ImageProvider<Object> Function(String)? provider;
  @override
  State<_RegionImage> createState() => _RegionImageState();
}

class _RegionImageState extends State<_RegionImage> {
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
    final generation = ++_generation;
    _imageSize = null;
    _failed = false;
    final path = widget.region.imageFilePath;
    if (path == null) {
      _provider = null;
      return;
    }
    _provider = widget.provider?.call(path) ?? FileImage(File(path));
    _stream = _provider!.resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener((info, synchronous) {
      final size =
          Size(info.image.width.toDouble(), info.image.height.toDouble());
      info.dispose();
      if (!mounted || generation != _generation) return;
      if (synchronous) {
        _imageSize = size;
      } else {
        setState(() => _imageSize = size);
      }
    }, onError: (Object error, StackTrace? stack) {
      if (!mounted || generation != _generation) return;
      setState(() => _failed = true);
    });
    _stream!.addListener(_listener!);
  }

  @override
  void dispose() {
    ++_generation;
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  void _update(RegionMapGeometry geometry) {
    widget.navigation.scale = geometry.scale;
    widget.navigation.center = geometry.center;
    widget.onChanged();
  }

  Widget _viewport(Widget child) => widget.canvasHeight == null
      ? Expanded(child: child)
      : _provider == null || _failed
          ? child
          : SizedBox(height: widget.canvasHeight, child: child);

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    return PlayerMenuPanel(
        key: const ValueKey('region-map-canvas-panel'),
        padding: EdgeInsets.zero,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _viewport(LayoutBuilder(builder: (context, constraints) {
            final size = _imageSize;
            if (_provider == null || _failed) {
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.map_outlined,
                            size: 48, color: theme.secondary),
                        const SizedBox(height: 16),
                        Text(
                            widget.text(
                                'Carte régionale indisponible. Les lieux restent consultables dans la liste.',
                                'Regional map unavailable. Locations remain available in the list.'),
                            style: theme.body,
                            textAlign: TextAlign.center),
                      ])));
            }
            if (size == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final geometry = RegionMapGeometry(
                viewport: constraints.biggest,
                imageSize: size,
                scale: widget.navigation.scale,
                center: widget.navigation.center);
            void selectAt(Offset position) {
              final normalized = geometry.unproject(position);
              final hits = widget.region.points
                  .where((point) =>
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
                          24)
                  .toList();
              if (hits.isNotEmpty) widget.onSelect(hits);
            }

            return Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    GestureBinding.instance.pointerSignalResolver.register(
                        event,
                        (_) => _update(geometry.zoom(
                            geometry.scale *
                                math.exp(-event.scrollDelta.dy / 500),
                            event.localPosition)));
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
                      _update(start
                          .zoom(start.scale * details.scale, _gestureFocal)
                          .pan(details.localFocalPoint - _gestureFocal));
                    }
                  },
                  child: ClipRect(
                      child: Stack(children: [
                    Positioned.fromRect(
                        rect: geometry.transformedImageRect,
                        child: Image(
                            image: _provider!,
                            fit: BoxFit.fill,
                            excludeFromSemantics: true,
                            filterQuality: widget.region.pixelArt
                                ? FilterQuality.none
                                : FilterQuality.medium,
                            errorBuilder: (context, error, stack) =>
                                const SizedBox.shrink())),
                    for (final point in widget.region.points
                        .where((point) => point.isLocated))
                      Positioned.fromRect(
                        rect: Rect.fromCenter(
                            center:
                                geometry.project(Offset(point.u!, point.v!)),
                            width: 48,
                            height: 48),
                        child: Semantics(
                            key: ValueKey('region-pin-${point.id}'),
                            button: true,
                            label: widget.label(point),
                            value: widget.status(point),
                            selected:
                                widget.navigation.selectedPointId == point.id,
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
                                          widget.navigation.selectedPointId ==
                                                  point.id
                                              ? theme.focus
                                              : theme.border,
                                      width:
                                          widget.navigation.selectedPointId ==
                                                  point.id
                                              ? 3
                                              : 1),
                                  boxShadow: [
                                    BoxShadow(
                                        color: theme.shadow, blurRadius: 6)
                                  ]),
                              child: Icon(widget.icon(point),
                                  size: 22, color: theme.accent),
                            ))))),
                      ),
                  ])),
                ));
          })),
          Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PlayerActionButton(
                        key: const ValueKey('region-map-zoom-out'),
                        label: widget.text('Réduire', 'Zoom out'),
                        icon: Icons.remove,
                        expandWidth: false,
                        onPressed: _imageSize == null ||
                                _failed ||
                                widget.navigation.scale <= 1
                            ? null
                            : () {
                                widget.navigation.scale =
                                    (widget.navigation.scale - .25).clamp(1, 3);
                                widget.onChanged();
                              }),
                    Semantics(
                        label: 'Zoom',
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                                '${(widget.navigation.scale * 100).round()} %',
                                style: theme.numbers))),
                    PlayerActionButton(
                        key: const ValueKey('region-map-zoom-in'),
                        label: widget.text('Agrandir', 'Zoom in'),
                        icon: Icons.add,
                        expandWidth: false,
                        onPressed: _imageSize == null ||
                                _failed ||
                                widget.navigation.scale >= 3
                            ? null
                            : () {
                                widget.navigation.scale =
                                    (widget.navigation.scale + .25).clamp(1, 3);
                                widget.onChanged();
                              }),
                    PlayerActionButton(
                        key: const ValueKey('region-map-recenter'),
                        label: widget.text('Recentrer', 'Recenter'),
                        icon: Icons.center_focus_strong,
                        expandWidth: false,
                        onPressed: _imageSize == null || _failed
                            ? null
                            : () {
                                widget.navigation.scale = 1;
                                widget.navigation.center = const Offset(.5, .5);
                                widget.onChanged();
                              }),
                  ])),
        ]));
  }
}
