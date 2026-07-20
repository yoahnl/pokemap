import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../design_system/design_system.dart';

class EventBuilderV2Editor extends StatelessWidget {
  const EventBuilderV2Editor({
    super.key,
    required this.event,
    this.onChangeSource,
    this.onSeeOnMap,
    this.onAddCondition,
    this.onChangeScene,
    this.onOpenScene,
    this.onChangeBehavior,
    this.onSimulate,
  });

  final NarrativeEventProjectSummary? event;
  final VoidCallback? onChangeSource;
  final VoidCallback? onSeeOnMap;
  final VoidCallback? onAddCondition;
  final VoidCallback? onChangeScene;
  final VoidCallback? onOpenScene;
  final VoidCallback? onChangeBehavior;
  final VoidCallback? onSimulate;

  @override
  Widget build(BuildContext context) {
    final selected = event;
    return PokeMapPanel(
      borderRadius: 8,
      expandChild: true,
      padding: EdgeInsets.zero,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 12, 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Éditeur d’événement',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected?.title ?? 'Aucun événement sélectionné',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected != null)
              PokeMapBadge(
                label: _eventStatusLabel(selected),
                variant: _eventBadgeVariant(selected),
                icon: Icon(
                  selected.readOnly
                      ? CupertinoIcons.lock
                      : selected.enabled == true
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                ),
              ),
          ],
        ),
      ),
      child: selected == null
          ? const PokeMapEmptyState(
              title: 'Sélectionnez un événement',
              description:
                  'Son déclencheur, ses conditions et sa Scene apparaîtront ici.',
              icon: Icon(CupertinoIcons.bolt_horizontal_circle),
            )
          : ListView(
              key: const ValueKey('event-builder-v2-editor-scroll'),
              padding: const EdgeInsets.fromLTRB(18, 14, 16, 18),
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    key: const ValueKey('event-builder-v2-flow-rail'),
                    constraints: const BoxConstraints(maxWidth: 404),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: 304,
                              child: _EditorBlock(
                                key: const ValueKey(
                                  'event-builder-v2-source-block',
                                ),
                                title: 'Déclencheur',
                                subtitle: selected.source.humanSentence,
                                icon: CupertinoIcons.bolt_fill,
                                tone: selected.source.available
                                    ? PokeMapTone.narrative
                                    : PokeMapTone.warning,
                                readOnly: selected.readOnly,
                              ),
                            ),
                          ),
                          const Align(
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: 304,
                              child: _FlowConnector(),
                            ),
                          ),
                          _EditorBlock(
                            key: const ValueKey(
                              'event-builder-v2-conditions-block',
                            ),
                            title: 'Conditions',
                            subtitle: selected.conditions.humanLabel,
                            icon: CupertinoIcons.checkmark_alt_circle_fill,
                            tone: selected.conditions.valid
                                ? PokeMapTone.info
                                : PokeMapTone.warning,
                            readOnly: selected.readOnly,
                            actions: [
                              if (!selected.readOnly && onAddCondition != null)
                                PokeMapButton(
                                  onPressed: onAddCondition,
                                  variant: PokeMapButtonVariant.ghost,
                                  size: PokeMapButtonSize.small,
                                  leading: const Icon(CupertinoIcons.add),
                                  child: const Text('Ajouter une condition'),
                                ),
                              if (!selected.readOnly && onSimulate != null)
                                PokeMapButton(
                                  key: const ValueKey(
                                    'event-builder-v2-open-simulation',
                                  ),
                                  onPressed: onSimulate,
                                  variant: PokeMapButtonVariant.secondary,
                                  size: PokeMapButtonSize.small,
                                  leading: const Icon(CupertinoIcons.play_fill),
                                  child: const Text('Tester'),
                                ),
                            ],
                            details: [
                              const _CompactProperty(
                                label: 'Mode',
                                value: 'Toutes (AND) doivent être remplies',
                              ),
                              if (selected.conditions.details.isEmpty)
                                const _CompactProperty(
                                  label: 'Ordre',
                                  value: 'Aucune condition',
                                )
                              else
                                for (var index = 0;
                                    index < selected.conditions.details.length;
                                    index++)
                                  _CompactProperty(
                                    label: 'Condition ${index + 1}',
                                    value: selected
                                        .conditions.details[index].humanLabel,
                                  ),
                            ],
                          ),
                          const _FlowConnector(),
                          _EditorBlock(
                            key: const ValueKey(
                              'event-builder-v2-scene-block',
                            ),
                            title: 'Scene à jouer',
                            subtitle: selected.scene.humanLabel,
                            icon: CupertinoIcons.play_rectangle_fill,
                            tone: selected.scene.valid
                                ? PokeMapTone.success
                                : PokeMapTone.warning,
                            readOnly: selected.readOnly,
                            actions: [
                              if (!selected.readOnly && onChangeScene != null)
                                PokeMapButton(
                                  onPressed: onChangeScene,
                                  variant: PokeMapButtonVariant.ghost,
                                  size: PokeMapButtonSize.small,
                                  child: const Text('Choisir une Scene'),
                                ),
                              if (selected.scene.sceneId != null &&
                                  onOpenScene != null)
                                PokeMapButton(
                                  onPressed: onOpenScene,
                                  variant: PokeMapButtonVariant.ghost,
                                  size: PokeMapButtonSize.small,
                                  leading: const Icon(
                                    CupertinoIcons.arrow_up_right_square,
                                  ),
                                  child: const Text('Ouvrir la Scene'),
                                ),
                            ],
                          ),
                          const _FlowConnector(),
                          _SceneProjectionBlock(
                            event: selected,
                            onOpenScene: onOpenScene,
                          ),
                          const _FlowConnector(),
                          const Center(
                            child: PokeMapBadge(
                              label: 'Fin de l’événement',
                              variant: PokeMapBadgeVariant.neutral,
                              icon: Icon(CupertinoIcons.flag),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EditorBlock extends StatelessWidget {
  const _EditorBlock({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.readOnly,
    this.details = const [],
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final PokeMapTone tone;
  final bool readOnly;
  final List<Widget> details;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.resolve(context);
    return Semantics(
      container: true,
      label: readOnly ? '$title, lecture seule' : title,
      child: PokeMapCard(
        borderRadius: 7,
        backgroundColor: toneColors.soft,
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PokeMapIconTile(
                  icon: icon,
                  tone: tone,
                  size: 30,
                  iconSize: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: toneColors.text,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.25,
                              ),
                            ),
                          ),
                          if (readOnly)
                            const PokeMapBadge(
                              label: 'Lecture seule',
                              variant: PokeMapBadgeVariant.neutral,
                              icon: Icon(CupertinoIcons.lock),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 7),
              for (var index = 0; index < details.length; index++) ...[
                details[index],
                if (index < details.length - 1) const SizedBox(height: 4),
              ],
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 7),
              Wrap(spacing: 6, runSpacing: 6, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactProperty extends StatelessWidget {
  const _CompactProperty({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, $value, lecture seule',
      child: PokeMapCard(
        borderRadius: 6,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(CupertinoIcons.lock, size: 10),
          ],
        ),
      ),
    );
  }
}

class _SceneProjectionBlock extends StatelessWidget {
  const _SceneProjectionBlock({required this.event, this.onOpenScene});

  final NarrativeEventProjectSummary event;
  final VoidCallback? onOpenScene;

  @override
  Widget build(BuildContext context) {
    final projection = event.projection;
    final outcomes = projection.outcomeLabels;
    return Semantics(
      container: true,
      label: 'Projections de la Scene, lecture seule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ProjectionBand(
            title: 'Résultats possibles',
            icon: CupertinoIcons.flag_fill,
            tone: PokeMapTone.info,
          ),
          if (outcomes.length >= 2)
            const _OutcomeBranchConnector()
          else
            const SizedBox(height: 6),
          _OutcomeBranches(outcomes: outcomes),
          const SizedBox(height: 7),
          _ProjectionGroup(
            title: 'Réactions et conséquences',
            icon: CupertinoIcons.bolt_circle_fill,
            tone: PokeMapTone.warning,
            emptyLabel: 'Aucune conséquence détectée dans la Scene.',
            labels: [
              for (final consequence in projection.consequences)
                consequence.humanLabel,
            ],
          ),
          const SizedBox(height: 7),
          _ProjectionGroup(
            title: 'Changements du monde',
            icon: CupertinoIcons.globe,
            tone: PokeMapTone.map,
            emptyLabel: 'Aucun changement du monde détecté.',
            labels: [
              for (final rule in projection.worldRules) rule.humanLabel,
            ],
          ),
          if (event.scene.sceneId != null && onOpenScene != null) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerLeft,
              child: PokeMapButton(
                onPressed: onOpenScene,
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.arrow_up_right_square),
                child: const Text('Voir dans la Scene'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectionBand extends StatelessWidget {
  const _ProjectionBand({
    required this.title,
    required this.icon,
    required this.tone,
  });

  final String title;
  final IconData icon;
  final PokeMapTone tone;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.resolve(context);
    return PokeMapCard(
      borderRadius: 6,
      backgroundColor: toneColors.soft,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 13, color: toneColors.icon),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: toneColors.text,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.25,
              ),
            ),
          ),
          const PokeMapBadge(
            label: 'Lecture seule',
            variant: PokeMapBadgeVariant.neutral,
            icon: Icon(CupertinoIcons.lock),
          ),
        ],
      ),
    );
  }
}

class _OutcomeBranches extends StatelessWidget {
  const _OutcomeBranches({required this.outcomes});

  final List<String> outcomes;

  @override
  Widget build(BuildContext context) {
    final count = outcomes.length;
    return KeyedSubtree(
      key: ValueKey('event-builder-v2-outcomes-$count'),
      child: switch (count) {
        0 => const _ProjectionEmpty(
            label: 'Aucun résultat déclaré dans la Scene.',
          ),
        1 => _OutcomeCard(label: outcomes.single),
        2 => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _OutcomeCard(label: outcomes[0])),
              const SizedBox(width: 8),
              Expanded(child: _OutcomeCard(label: outcomes[1])),
            ],
          ),
        _ => LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 5,
                children: [
                  for (final outcome in outcomes)
                    SizedBox(
                      width: cardWidth,
                      child: _OutcomeCard(label: outcome),
                    ),
                ],
              );
            },
          ),
      },
    );
  }
}

/// Draws the only non-linear connector in the Event projection.
///
/// Outcome meaning and reactions remain Scene-owned and read-only; this line is
/// purely a visual projection of the two-column result layout. Four or more
/// outcomes still reuse those two columns, so the connector never fabricates a
/// semantic branch count from labels alone.
class _OutcomeBranchConnector extends StatelessWidget {
  const _OutcomeBranchConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('event-builder-v2-outcome-branch-connector'),
      height: 18,
      child: CustomPaint(
        painter: _OutcomeBranchConnectorPainter(
          color: PokeMapTone.neutral.resolve(context).border,
        ),
      ),
    );
  }
}

class _OutcomeBranchConnectorPainter extends CustomPainter {
  const _OutcomeBranchConnectorPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final center = size.width / 2;
    final leftBranch = size.width / 4;
    final rightBranch = size.width * 3 / 4;
    const branchY = 9.0;
    canvas
      ..drawLine(Offset(center, 0), Offset(center, branchY), paint)
      ..drawLine(
          Offset(leftBranch, branchY), Offset(rightBranch, branchY), paint)
      ..drawLine(
          Offset(leftBranch, branchY), Offset(leftBranch, size.height), paint)
      ..drawLine(Offset(rightBranch, branchY), Offset(rightBranch, size.height),
          paint);
  }

  @override
  bool shouldRepaint(covariant _OutcomeBranchConnectorPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    // The projection currently carries display labels, not typed outcome
    // semantics. A neutral narrative treatment avoids presenting the first
    // item as success and the second as failure when a Scene orders them
    // differently.
    const tone = PokeMapTone.narrative;
    final toneColors = tone.resolve(context);
    return Semantics(
      label: '$label, résultat de Scene, lecture seule',
      child: PokeMapCard(
        borderRadius: 6,
        backgroundColor: toneColors.soft,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              CupertinoIcons.flag_fill,
              size: 13,
              color: toneColors.icon,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectionGroup extends StatelessWidget {
  const _ProjectionGroup({
    required this.title,
    required this.icon,
    required this.tone,
    required this.emptyLabel,
    required this.labels,
  });

  final String title;
  final IconData icon;
  final PokeMapTone tone;
  final String emptyLabel;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.resolve(context);
    return PokeMapCard(
      borderRadius: 7,
      backgroundColor: toneColors.soft,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: toneColors.icon),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: toneColors.text,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.25,
                  ),
                ),
              ),
              const Icon(CupertinoIcons.lock, size: 10),
            ],
          ),
          const SizedBox(height: 6),
          if (labels.isEmpty)
            _ProjectionEmpty(label: emptyLabel)
          else
            for (var index = 0; index < labels.length; index++) ...[
              _ProjectionLine(label: labels[index], tone: tone),
              if (index < labels.length - 1) const SizedBox(height: 4),
            ],
        ],
      ),
    );
  }
}

class _ProjectionLine extends StatelessWidget {
  const _ProjectionLine({required this.label, required this.tone});

  final String label;
  final PokeMapTone tone;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      borderRadius: 5,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.eye, size: 11, color: tone.resolve(context).icon),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectionEmpty extends StatelessWidget {
  const _ProjectionEmpty({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      borderRadius: 6,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const Icon(CupertinoIcons.eye_slash, size: 12),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowConnector extends StatelessWidget {
  const _FlowConnector();

  @override
  Widget build(BuildContext context) {
    final connector = PokeMapTone.neutral.resolve(context).border;
    return SizedBox(
      height: 18,
      child: Center(
        child: Column(
          children: [
            Icon(CupertinoIcons.circle_fill, size: 4, color: connector),
            Expanded(child: Container(width: 1, color: connector)),
            Icon(CupertinoIcons.circle_fill, size: 4, color: connector),
          ],
        ),
      ),
    );
  }
}

String _eventStatusLabel(NarrativeEventProjectSummary event) {
  if (event.readOnly) return 'Lecture seule';
  if (event.enabled == true) return 'Actif';
  if (event.status == NarrativeEventProjectStatus.draftIncomplete) {
    return 'Brouillon';
  }
  return 'Inactif';
}

PokeMapBadgeVariant _eventBadgeVariant(NarrativeEventProjectSummary event) {
  if (event.readOnly) return PokeMapBadgeVariant.warning;
  if (event.enabled == true) return PokeMapBadgeVariant.success;
  if (event.status == NarrativeEventProjectStatus.draftIncomplete) {
    return PokeMapBadgeVariant.neutral;
  }
  return PokeMapBadgeVariant.info;
}
