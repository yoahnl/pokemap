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
  });

  final Animation<double> progress;
  final AveluneSplashPalette palette;
  final bool reducedMotion;
  final bool active;

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
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: AveluneSplashPainter(
        progress: widget.progress,
        ambient: _ambient,
        wordmark: _wordmark?.image,
        brand: widget.palette,
        reducedMotion: _reducedMotion,
      ),
      child: const SizedBox.expand(),
    ),
  );
}
