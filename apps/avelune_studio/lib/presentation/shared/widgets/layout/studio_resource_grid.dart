import 'package:flutter/material.dart';

class StudioResourceGrid extends StatelessWidget {
  const StudioResourceGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
  });
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => GridView.builder(
    controller: controller,
    scrollCacheExtent: const ScrollCacheExtent.pixels(0),
    padding: const EdgeInsets.all(12),
    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 230,
      mainAxisExtent:
          210 +
          (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(0, 40) * 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: itemCount,
    itemBuilder: itemBuilder,
  );
}
