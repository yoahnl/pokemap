import 'package:flutter/widgets.dart';

class MinimumSizeViewport extends StatelessWidget {
  const MinimumSizeViewport({
    super.key,
    required this.minimum,
    required this.child,
  });

  final Size minimum;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < minimum.width
          ? minimum.width
          : constraints.maxWidth;
      final height = constraints.maxHeight < minimum.height
          ? minimum.height
          : constraints.maxHeight;
      if (width == constraints.maxWidth && height == constraints.maxHeight) {
        return child;
      }
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: SizedBox(width: width, height: height, child: child),
        ),
      );
    },
  );
}
