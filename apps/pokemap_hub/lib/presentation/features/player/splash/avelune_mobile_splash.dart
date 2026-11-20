import 'package:flutter/widgets.dart';

import 'avelune_mobile_splash_palette.dart';
import 'avelune_mobile_splash_painter.dart';

class AveluneMobileSplash extends StatefulWidget {
  const AveluneMobileSplash({
    super.key,
    required this.progress,
    required this.palette,
    required this.reducedMotion,
  });

  final Animation<double> progress;
  final AveluneMobileSplashPalette palette;
  final bool reducedMotion;

  @override
  State<AveluneMobileSplash> createState() => _AveluneMobileSplashState();
}

class _AveluneMobileSplashState extends State<AveluneMobileSplash> {
  ImageStream? _stream;
  ImageInfo? _wordmark;
  late final _listener = ImageStreamListener(
    _imageReady,
    onError: (error, stack) {},
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveWordmark();
  }

  @override
  void didUpdateWidget(AveluneMobileSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.palette != widget.palette) _resolveWordmark();
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
    _stream?.removeListener(_listener);
    _wordmark?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: AveluneMobileSplashPainter(
        progress: widget.progress,
        wordmark: _wordmark?.image,
        brand: widget.palette,
        reducedMotion:
            widget.reducedMotion || MediaQuery.disableAnimationsOf(context),
      ),
      child: const SizedBox.expand(),
    ),
  );
}
