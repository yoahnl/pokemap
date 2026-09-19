import 'package:flutter/material.dart';

class MapPaletteGrid extends StatefulWidget {
  const MapPaletteGrid({
    super.key,
    required this.count,
    required this.itemBuilder,
    required this.offset,
    required this.onScroll,
    this.columns = 2,
  });
  final int count;
  final IndexedWidgetBuilder itemBuilder;
  final double offset;
  final ValueChanged<double> onScroll;
  final int columns;
  @override
  State<MapPaletteGrid> createState() => _MapPaletteGridState();
}

class _MapPaletteGridState extends State<MapPaletteGrid> {
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: widget.offset,
  )..addListener(() => widget.onScroll(_scroll.offset));
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GridView.builder(
    controller: _scroll,
    scrollCacheExtent: const ScrollCacheExtent.pixels(0),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: widget.columns,
      mainAxisExtent:
          104 + 16 * (MediaQuery.textScalerOf(context).scale(1) - 1),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
    ),
    itemCount: widget.count,
    itemBuilder: widget.itemBuilder,
  );
}
