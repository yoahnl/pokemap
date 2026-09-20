import 'package:flutter/material.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../theme/studio_tokens.dart';

class StudioHomeTools extends StatelessWidget {
  const StudioHomeTools({
    super.key,
    required this.onDestination,
    required this.hasProject,
    required this.canTest,
    required this.busy,
  });
  final ValueChanged<String> onDestination;
  final bool hasProject, canTest, busy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accents = StudioColors.of(context);
    final tools = [
      (
        'Carte',
        'Créez et composez\nvotre monde',
        Icons.map_outlined,
        'map',
        accents.success,
      ),
      (
        'Ressources',
        'Retrouvez vos images\net vos décors',
        Icons.landscape_outlined,
        'resources',
        colors.primary,
      ),
      (
        'Terrains',
        'Des raccords\nautomatiques',
        Icons.extension_outlined,
        'terrains',
        accents.featureAccent,
      ),
      (
        'Placer un personnage',
        'Donnez vie à\nvos rencontres',
        Icons.person_outline,
        'characters',
        accents.warning,
      ),
      (
        'Histoire',
        'Dialogues, conditions\net petites histoires',
        Icons.menu_book_outlined,
        'story',
        colors.error,
      ),
      (
        'Tester',
        'Jouez et vérifiez\nvotre création',
        Icons.play_arrow_outlined,
        'test',
        accents.canvasSelection,
      ),
    ];
    return StudioPanel(
      title: 'Vos outils de création',
      compact: true,
      children: [
        Text(
          'Tout ce dont vous avez besoin, au même endroit.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final count = constraints.maxWidth >= 870 * scale
                ? 6
                : constraints.maxWidth >= 430
                ? 3
                : 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final tool in tools)
                  SizedBox(
                    width: (constraints.maxWidth - (count - 1) * 10) / count,
                    child: Tooltip(
                      message: hasProject
                          ? tool.$1
                          : 'Ouvrez un projet pour utiliser cet outil',
                      child: Material(
                        color: tool.$5.withValues(alpha: .09),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: tool.$5.withValues(alpha: .4),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('home-tool-${tool.$4}'),
                          onTap: !busy && (tool.$4 != 'test' || canTest)
                              ? () => onDestination(tool.$4)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: tool.$5,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    tool.$3,
                                    color: colors.surfaceContainerLowest,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  tool.$1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  tool.$2,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(
                                    hasProject
                                        ? Icons.arrow_forward
                                        : Icons.lock_outline,
                                    size: 17,
                                    color: tool.$5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
