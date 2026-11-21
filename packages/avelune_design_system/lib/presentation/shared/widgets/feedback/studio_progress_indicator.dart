import 'package:flutter/material.dart';

class StudioProgressIndicator extends StatelessWidget {
  const StudioProgressIndicator({super.key, this.label})
    : size = null,
      _strokeWidth = 4;

  const StudioProgressIndicator.compact({super.key, this.label, this.size = 16})
    : _strokeWidth = 2;

  final String? label;
  final double? size;
  final double _strokeWidth;

  @override
  Widget build(BuildContext context) {
    final indicator = CircularProgressIndicator(
      semanticsLabel: label,
      strokeWidth: _strokeWidth,
    );
    final size = this.size;
    return size == null
        ? indicator
        : SizedBox.square(dimension: size, child: indicator);
  }
}
