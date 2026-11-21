import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'avelune_splash_palette.dart';
import 'avelune_splash_painter.dart';

class AveluneSplash extends StatefulWidget {
  const AveluneSplash({
    super.key,
    required this.progress,
    required this.palette,
    required this.reducedMotion,
    required this.active,
  }) : details = null;

  const AveluneSplash.waiting({
    super.key,
    required this.palette,
    required this.reducedMotion,
    required this.active,
    required Widget this.details,
  }) : progress = kAlwaysCompleteAnimation;

  final Animation<double> progress;
  final AveluneSplashPalette palette;
  final bool reducedMotion;
  final bool active;
  final Widget? details;

  @override
  State<AveluneSplash> createState() => _AveluneSplashState();
}

class _AveluneSplashState extends State<AveluneSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  bool _systemReducedMotion = false;
  ImageStream? _stream;
  ImageInfo? _wordmark;
  late final _listener = ImageStreamListener(
    _imageReady,
    onError: (error, stack) {},
  );

  bool get _reducedMotion => widget.reducedMotion || _systemReducedMotion;

  @override
  void initState() {
    super.initState();
    widget.progress.addStatusListener(_syncAmbient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _systemReducedMotion = MediaQuery.disableAnimationsOf(context);
    _resolveWordmark();
    _syncAmbient(widget.progress.status);
  }

  @override
  void didUpdateWidget(AveluneSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      oldWidget.progress.removeStatusListener(_syncAmbient);
      widget.progress.addStatusListener(_syncAmbient);
    }
    if (oldWidget.palette != widget.palette) _resolveWordmark();
    _syncAmbient(widget.progress.status);
  }

  void _syncAmbient(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        widget.active &&
        !_reducedMotion) {
      if (!_ambient.isAnimating) _ambient.repeat();
    } else {
      _ambient.stop();
    }
  }

  void _resolveWordmark() {
    final next = widget.palette.wordmark.resolve(
      createLocalImageConfiguration(context),
    );
    if (_stream?.key == next.key) return;
    _stream?.removeListener(_listener);
    _stream = next;
    next.addListener(_listener);
  }

  void _imageReady(ImageInfo image, bool synchronousCall) {
    final previous = _wordmark;
    _wordmark = image;
    if (!synchronousCall) setState(() {});
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  @override
  void dispose() {
    widget.progress.removeStatusListener(_syncAmbient);
    _ambient.dispose();
    _stream?.removeListener(_listener);
    _wordmark?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    if (details == null) return _paint(AveluneSplashLayer.scene);
    return Stack(
      fit: StackFit.expand,
      children: [
        _paint(AveluneSplashLayer.atmosphere),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide =
                    constraints.maxWidth >= 600 &&
                    constraints.maxWidth >= constraints.maxHeight * 1.1;
                final artwork = SizedBox(
                  width: sideBySide ? 252 : 280,
                  height: math.min(
                    244,
                    constraints.maxHeight * (sideBySide ? .86 : .43),
                  ),
                  child: _paint(AveluneSplashLayer.branding),
                );
                final content = SizedBox(width: 320, child: details);
                return Center(
                  child: SingleChildScrollView(
                    child: Flex(
                      direction: sideBySide ? Axis.horizontal : Axis.vertical,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        artwork,
                        if (sideBySide)
                          const SizedBox(width: 28)
                        else
                          const SizedBox(height: 14),
                        content,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _paint(AveluneSplashLayer layer) => RepaintBoundary(
    child: CustomPaint(
      painter: AveluneSplashPainter(
        progress: widget.progress,
        ambient: _ambient,
        wordmark: _wordmark?.image,
        brand: widget.palette,
        reducedMotion: _reducedMotion,
        layer: layer,
      ),
      child: const SizedBox.expand(),
    ),
  );
}
