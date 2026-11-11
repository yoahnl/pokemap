import 'package:flutter/material.dart';

import '../../shared/widgets/layout/studio_sidebar.dart';

double mapLeftColumnWidth(double available) => available >= 1400
    ? 320
    : available >= 1100
    ? 288
    : 252;

class MapWorkspaceLeftColumn extends StatelessWidget {
  const MapWorkspaceLeftColumn({
    super.key,
    required this.width,
    required this.content,
  });

  final double width;
  final Widget content;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSidebar(
          width: width,
          child: Text(
            'Contenu',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: StudioSidebar(width: width, child: content),
        ),
      ],
    ),
  );
}
