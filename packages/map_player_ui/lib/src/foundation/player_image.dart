import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

final class PlayerImageLease {
  PlayerImageLease({required this.image, required this.onDispose});

  final ui.Image image;
  final void Function() onDispose;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    onDispose();
  }
}

typedef PlayerImageLoader = Future<PlayerImageLease> Function(
  String path, {
  required bool Function() isCurrent,
});

class PlayerImageScope extends InheritedTheme {
  const PlayerImageScope({
    super.key,
    required this.loader,
    required this.identity,
    required super.child,
  });

  final PlayerImageLoader? loader;
  final Object identity;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      PlayerImageScope(loader: loader, identity: identity, child: child);

  static PlayerImageScope? scopeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlayerImageScope>();

  static PlayerImageLoader? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlayerImageScope>()?.loader;

  @override
  bool updateShouldNotify(PlayerImageScope oldWidget) =>
      identity != oldWidget.identity ||
      (loader == null) != (oldWidget.loader == null);
}

class PlayerImageBuilder extends StatefulWidget {
  const PlayerImageBuilder({
    super.key,
    required this.path,
    required this.builder,
    this.fallback = const SizedBox.shrink(),
    this.errorBuilder,
  });

  final String path;
  final Widget Function(BuildContext context, ui.Image image) builder;
  final Widget fallback;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<PlayerImageBuilder> createState() => _PlayerImageBuilderState();
}

class _PlayerImageBuilderState extends State<PlayerImageBuilder> {
  Object? _identity;
  bool _hasLoader = false;
  PlayerImageLease? _lease;
  Object? _error;
  StackTrace? _errorStack;
  String? _path;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(PlayerImageBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  void _load() {
    final scope = PlayerImageScope.scopeOf(context);
    final loader = scope?.loader;
    if (scope?.identity == _identity &&
        _hasLoader == (loader != null) &&
        _path == widget.path) {
      return;
    }
    _identity = scope?.identity;
    _hasLoader = loader != null;
    _path = widget.path;
    final generation = ++_generation;
    _lease?.dispose();
    _lease = null;
    _error = null;
    _errorStack = null;
    if (loader != null) unawaited(_resolve(loader, widget.path, generation));
  }

  Future<void> _resolve(
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
      setState(() => _lease = lease);
    } on Object catch (error, stack) {
      if (current()) {
        setState(() {
          _lease = null;
          _error = error;
          _errorStack = stack;
        });
      }
    }
  }

  @override
  void dispose() {
    ++_generation;
    _lease?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lease = _lease;
    if (lease != null) return widget.builder(context, lease.image);
    final error = _error;
    return error == null
        ? widget.fallback
        : widget.errorBuilder?.call(context, error, _errorStack) ??
              widget.fallback;
  }
}

class PlayerFileImage extends StatelessWidget {
  const PlayerFileImage({
    super.key,
    required this.path,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.filterQuality = FilterQuality.medium,
    this.fallback = const SizedBox.shrink(),
    this.excludeFromSemantics = false,
    this.alignment = Alignment.center,
    this.errorBuilder,
    this.color,
    this.colorBlendMode,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final FilterQuality filterQuality;
  final Widget fallback;
  final bool excludeFromSemantics;
  final AlignmentGeometry alignment;
  final ImageErrorWidgetBuilder? errorBuilder;
  final Color? color;
  final BlendMode? colorBlendMode;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    excluding: excludeFromSemantics,
    child: PlayerImageBuilder(
      path: path,
      fallback: SizedBox(width: width, height: height, child: fallback),
      errorBuilder: errorBuilder,
      builder: (context, image) => RawImage(
        image: image,
        width: width,
        height: height,
        fit: fit,
        filterQuality: filterQuality,
        alignment: alignment,
        color: color,
        colorBlendMode: colorBlendMode,
      ),
    ),
  );
}

class PlayerProvidedImage extends StatelessWidget {
  const PlayerProvidedImage({
    super.key,
    required this.image,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.errorBuilder,
    this.filterQuality = FilterQuality.medium,
    this.color,
    this.colorBlendMode,
  });

  final ImageProvider image;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final String? semanticLabel;
  final ImageErrorWidgetBuilder? errorBuilder;
  final FilterQuality filterQuality;
  final Color? color;
  final BlendMode? colorBlendMode;

  @override
  Widget build(BuildContext context) {
    ImageProvider source = image;
    while (source is ResizeImage) {
      source = source.imageProvider;
    }
    if (source is FileImage) {
      return Semantics(
        label: semanticLabel,
        image: true,
        child: PlayerFileImage(
          path: source.file.path,
          fit: fit,
          alignment: alignment,
          filterQuality: filterQuality,
          errorBuilder: errorBuilder,
          color: color,
          colorBlendMode: colorBlendMode,
        ),
      );
    }
    return Image(
      image: image,
      fit: fit,
      alignment: alignment,
      semanticLabel: semanticLabel,
      errorBuilder: errorBuilder,
      filterQuality: filterQuality,
      color: color,
      colorBlendMode: colorBlendMode,
    );
  }
}
