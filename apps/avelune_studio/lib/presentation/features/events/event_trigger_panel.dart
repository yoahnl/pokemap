import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/events/application/event_workspace_controller.dart';
import '../../../features/events/application/event_source_selection_session.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'event_context_map.dart';

import 'package:avelune_studio/features/events/application/event_map_loader.dart';

import 'event_view_state.dart';
import 'event_labels.dart';
import 'event_outcome_picker.dart';
import 'event_source_identity.dart';
import '../../shared/widgets/feedback/studio_icon_tile.dart';

class EventTriggerPanel extends StatefulWidget {
  const EventTriggerPanel({
    super.key,
    required this.controller,
    required this.record,
    required this.loader,
    required this.visuals,
    required this.view,
    required this.onLocate,
    required this.onProducer,
  });
  final EventWorkspaceController controller;
  final NarrativeEventRecord record;
  final EventMapLoader loader;
  final MapWorkspaceVisuals visuals;
  final EventViewState view;
  final ValueChanged<NarrativeEventSourceRef> onLocate;
  final ValueChanged<String>? onProducer;
  @override
  State<EventTriggerPanel> createState() => _EventTriggerPanelState();
}

class _EventTriggerPanelState extends State<EventTriggerPanel> {
  late final EventSourceSelectionSession _selection;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _selection = EventSourceSelectionSession(
      controller: widget.controller,
      loader: widget.loader,
      record: widget.record,
      changed: () {
        if (mounted) setState(() => _notice = null);
      },
    );
  }

  @override
  void didUpdateWidget(EventTriggerPanel old) {
    super.didUpdateWidget(old);
    _selection.configure(
      controller: widget.controller,
      loader: widget.loader,
      record: widget.record,
    );
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  Future<void> _choose(NarrativeEventSourceKind kind) async {
    await _selection.choose(
      kind,
      chooseOutcome: () =>
          chooseEventOutcome(context, widget.controller.catalog.outcomeSources),
    );
  }

  void _accept(NarrativeEventSourceRef source) => _selection.accept(source);

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final source = eventSource(record);
    final kind = _selection.choosing ?? source?.kind;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        final controls = SingleChildScrollView(
          child: StudioPanel(
            compact: true,
            title: 'Type de déclencheur',
            children: [
              for (final type in eventSourceKinds)
                if (type != NarrativeEventSourceKind.modelInteract ||
                    widget.controller.project.settings.dimension ==
                        ProjectDimension.threeD)
                  if ((type != NarrativeEventSourceKind.entityBump &&
                          type != NarrativeEventSourceKind.entityAutorun &&
                          type != NarrativeEventSourceKind.triggerBump) ||
                      widget.controller.project.settings.dimension ==
                          ProjectDimension.twoD)
                    StudioChoice(
                      label: eventKindLabel(type),
                      selected: kind == type,
                      tone: eventKindTone(type),
                      leading: StudioIconTile(
                        icon: eventKindIcon(type),
                        tone: eventKindTone(type),
                        size: 30,
                      ),
                      onTap: () => _choose(type),
                    ),
              if (kind == NarrativeEventSourceKind.triggerBump) ...[
                const SizedBox(height: 8),
                const StudioNotice(
                  'L’événement se déclenche quand une tentative de marche est bloquée contre cette zone.',
                ),
              ],
              if (kind == NarrativeEventSourceKind.entityBump) ...[
                const SizedBox(height: 8),
                const StudioNotice(
                  'L’événement se déclenche quand le joueur marche contre un personnage bloquant.',
                ),
              ],
              if (kind == NarrativeEventSourceKind.entityAutorun) ...[
                const SizedBox(height: 8),
                const StudioNotice(
                  'L’événement démarre automatiquement pour cet élément lorsque ses conditions sont réunies, sans action du joueur.',
                ),
              ],
              const SizedBox(height: 14),
              if (kind != NarrativeEventSourceKind.outcomeReceived) ...[
                StudioSelect(
                  label: _selection.choosing == null
                      ? 'Consulter une carte'
                      : 'Carte de la source',
                  value: _selection.mapId,
                  options: {
                    for (final e in widget.controller.project.maps)
                      e.id: '${e.name} · ${e.id}',
                  },
                  onChanged: _selection.selectMap,
                ),
                const SizedBox(height: 10),
                if (eventMapId(source) != null)
                  EventSourceIdentity(source: source!, loader: widget.loader),
                const SizedBox(height: 12),
                StudioButton(
                  label: 'Sélectionner sur la carte',
                  secondary: true,
                  icon: Icons.my_location,
                  onPressed: () =>
                      _choose(kind ?? NarrativeEventSourceKind.entityInteract),
                ),
                if (source != null) ...[
                  const SizedBox(height: 8),
                  StudioButton(
                    label: 'Voir sur la carte',
                    secondary: true,
                    icon: Icons.map_outlined,
                    onPressed: () => widget.onLocate(source),
                  ),
                ],
              ],
              if (_selection.choosing != null) ...[
                const SizedBox(height: 10),
                const StudioNotice(
                  'Choisissez une cible surlignée. Déplacez l’aperçu avec la main. Échap annule.',
                ),
                StudioButton(
                  label: 'Annuler le choix',
                  secondary: true,
                  onPressed: _selection.cancel,
                ),
              ],
              if (source != null) ...[
                const SizedBox(height: 12),
                StudioButton(
                  label: 'Retirer la source',
                  secondary: true,
                  onPressed: () async {
                    if (await widget.controller.prepare() && mounted) {
                      widget.controller.setSource(record.id, null);
                    }
                  },
                ),
              ],
              if (_notice != null) StudioNotice(_notice!),
            ],
          ),
        );
        final preview =
            kind == NarrativeEventSourceKind.outcomeReceived &&
                _selection.choosing == null
            ? EventOutcomeSummary(
                source: source,
                controller: widget.controller,
                onOpenProducer: widget.onProducer,
              )
            : _selection.pendingMap == null
            ? const StudioPanel(
                title: 'Contexte',
                children: [
                  Text(
                    'Choisissez une carte. Sa consultation ne modifie pas le document actif.',
                  ),
                ],
              )
            : FutureBuilder<MapData>(
                future: _selection.pendingMap,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done ||
                      snapshot.data?.id != _selection.mapId &&
                          !snapshot.hasError) {
                    return const Center(child: Text('Chargement de la carte…'));
                  }
                  if (snapshot.hasError) {
                    return StudioNotice(
                      'Carte indisponible : ${snapshot.error}',
                      isError: true,
                    );
                  }
                  final map = snapshot.data;
                  if (map == null) {
                    return const Center(child: Text('Chargement de la carte…'));
                  }
                  final targetId = eventTargetId(source);
                  final missing =
                      _selection.choosing == null &&
                      source != null &&
                      eventMapId(source) == map.id &&
                      targetId != null &&
                      !map.entities.any((e) => e.id == targetId) &&
                      !map.triggers.any((t) => t.id == targetId);
                  final missingModel =
                      source?.kind == NarrativeEventSourceKind.modelInteract &&
                      _selection.choosing == null &&
                      eventMapId(source) == map.id &&
                      !(map.spatialScene?.instances.any(
                            (instance) => instance.id == targetId,
                          ) ??
                          false);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          eventMapLabel(widget.controller.project, map.id),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (source?.kind == NarrativeEventSourceKind.modelInteract
                          ? missingModel
                          : missing)
                        const StudioNotice(
                          'La cible est absente. Sa référence est conservée pour réparation.',
                        ),
                      Expanded(
                        child: EventContextMap(
                          key: ValueKey('context:${record.id}:${map.id}'),
                          map: map,
                          project: widget.controller.project,
                          visuals: widget.visuals,
                          transform: widget.view.transform(
                            '${record.id}:${map.id}',
                          ),
                          source: source,
                          chooseKind: _selection.choosing,
                          selectableSources: _selection.choosing == null
                              ? null
                              : widget.controller.catalog.spatialSources.options
                                    .where(
                                      (o) => o.selectable && o.source != null,
                                    )
                                    .map((o) => o.source!)
                                    .toSet(),
                          onChoose: _accept,
                          onCancel: _selection.cancel,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selection.choosing == null
                            ? 'Aperçu en lecture seule · glisser pour déplacer, molette pour zoomer'
                            : 'Choix de source · aucun placement ni écriture de carte',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                },
              );
        return narrow
            ? ListView(
                children: [
                  controls,
                  const SizedBox(height: 12),
                  SizedBox(height: 400, child: preview),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 238, child: controls),
                  const SizedBox(width: 12),
                  Expanded(child: preview),
                ],
              );
      },
    );
  }
}
