import 'package:flutter/cupertino.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class EventBuilderCentralFlow extends StatelessWidget {
  const EventBuilderCentralFlow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.eventHeader,
    required this.blocks,
  });

  final String title;
  final String subtitle;
  final Widget eventHeader;
  final List<Widget> blocks;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('event-builder-central-flow'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PokeMapIconTile(
                  icon: CupertinoIcons.flowchart,
                  tone: PokeMapTone.quest,
                  size: 36,
                  iconSize: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            eventHeader,
            const SizedBox(height: 10),
            for (var index = 0; index < blocks.length; index++) ...[
              blocks[index],
              if (index < blocks.length - 1) const _FlowConnector(),
            ],
          ],
        ),
      ),
    );
  }
}

class _FlowConnector extends StatelessWidget {
  const _FlowConnector();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return SizedBox(
      key: const ValueKey('event-builder-flow-connector'),
      height: 18,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 1, height: 18, color: colors.borderSubtle),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: colors.controlSurface,
                border: Border.all(color: colors.borderSubtle),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.plus,
                size: 10,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
