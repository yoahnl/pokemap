import 'package:flutter/material.dart';

import '../../shared/widgets/inputs/studio_choice.dart';
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
    required this.contentSelected,
    required this.onContentSelected,
    required this.maps,
    required this.content,
  });

  final double width;
  final bool contentSelected;
  final ValueChanged<bool> onContentSelected;
  final Widget maps, content;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSidebar(
          width: width,
          child: Row(
            children: [
              for (final (isContent, label, key) in const [
                (false, 'Cartes', 'map-left-tab-maps'),
                (true, 'Contenu', 'map-left-tab-content'),
              ]) ...[
                if (isContent) const SizedBox(width: 6),
                Expanded(
                  child: StudioChoice(
                    key: ValueKey(key),
                    label: label,
                    dense: true,
                    selected: contentSelected == isContent,
                    onTap: () => onContentSelected(isContent),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: contentSelected ? 1 : 0,
            sizing: StackFit.expand,
            children: [
              maps,
              StudioSidebar(width: width, child: content),
            ],
          ),
        ),
      ],
    ),
  );
}
