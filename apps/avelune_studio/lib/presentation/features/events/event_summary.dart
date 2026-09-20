import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'event_labels.dart';
import 'event_condition_labels.dart';
import 'event_view_state.dart';
import 'event_scene_effects.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/feedback/studio_icon_tile.dart';
import 'event_status_badge.dart';

class EventSummary extends StatelessWidget {
  const EventSummary({
    super.key,
    required this.record,
    required this.project,
    required this.onTab,
    required this.onScene,
    required this.sceneDirty,
  });
  final NarrativeEventRecord record;
  final ProjectManifest project;
  final ValueChanged<EventTab> onTab;
  final VoidCallback? onScene;
  final bool sceneDirty;
  @override
  Widget build(BuildContext context) {
    final source = eventSource(record);
    final scene = project.scenes
        .where((s) => s.id == eventSceneId(record))
        .firstOrNull;
    return SingleChildScrollView(
      child: StudioPanel(
        compact: true,
        title: 'Résumé du comportement',
        children: [
          StudioChoice(
            label: 'Quand',
            tone: eventKindTone(source?.kind),
            subtitle: eventKindLabel(source?.kind),
            leading: StudioIconTile(
              icon: eventKindIcon(source?.kind),
              tone: eventKindTone(source?.kind),
            ),
            onTap: () => onTab(EventTab.trigger),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 17),
            child: Icon(Icons.arrow_downward, size: 18),
          ),
          StudioChoice(
            label: 'Si',
            tone: StudioTone.success,
            subtitle: eventExpressionLabel(
              eventExpression(record),
              project.facts,
              project.eventRegistry?.records ?? [],
            ),
            leading: const StudioIconTile(
              icon: Icons.rule,
              tone: StudioTone.success,
            ),
            onTap: () => onTab(EventTab.conditions),
          ),
          Text(
            'Conditions non évaluées · utiliser la simulation',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 17),
            child: Icon(Icons.arrow_downward, size: 18),
          ),
          StudioChoice(
            label: 'Jouer la scène',
            tone: StudioTone.feature,
            subtitle: scene?.name ?? eventSceneId(record) ?? 'Scène à choisir',
            leading: const StudioIconTile(
              icon: Icons.play_arrow_rounded,
              tone: StudioTone.feature,
            ),
            onTap: () => onTab(EventTab.scene),
          ),
          if (sceneDirty)
            const StudioNotice(
              'Cette scène contient des modifications locales.',
            ),
          const SizedBox(height: 12),
          if (scene != null) ...[
            const StudioBadge(
              'Conséquences possibles',
              tone: StudioTone.warning,
              icon: Icons.flag_outlined,
            ),
            const SizedBox(height: 8),
            Text(
              '${scene.graph.nodes.length} blocs dans la scène',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Conséquences possibles selon le chemin. Les actions et leurs branches se modifient dans l’éditeur de scène.',
            ),
            for (final effect in eventSceneEffects(scene, project))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('• $effect'),
              ),
          ],
          const SizedBox(height: 16),
          StudioButton(
            label: 'Ouvrir la scène',
            icon: Icons.open_in_new,
            secondary: true,
            onPressed: onScene,
          ),
          const SizedBox(height: 16),
          StudioChoice(
            label: 'Après le déclenchement',
            subtitle: switch (record.definitionOrNull?.reusePolicy ??
                record.draftOrNull?.reusePolicy) {
              NarrativeEventReusePolicy.reusable => 'Peut être rejoué',
              NarrativeEventReusePolicy.oneShot =>
                'Une seule occurrence · réarmement dans Options',
              null => 'À définir dans Options',
            },
            leading: const Icon(Icons.replay),
            onTap: () => onTab(EventTab.options),
          ),
          const SizedBox(height: 16),
          EventStatusBadge(record: record),
          const SizedBox(height: 6),
          SelectableText(
            record.id,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
