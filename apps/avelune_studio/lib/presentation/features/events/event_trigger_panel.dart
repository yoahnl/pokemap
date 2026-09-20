import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/events/application/event_workspace_controller.dart';
import '../map_workspace/map_workspace_visuals.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'event_context_map.dart';
import 'event_map_loader.dart';
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
  final ValueChanged<String> onProducer;
  @override
  State<EventTriggerPanel> createState() => _EventTriggerPanelState();
}

class _EventTriggerPanelState extends State<EventTriggerPanel> {
  String? _mapId;
  NarrativeEventSourceKind? _choosing;
  Future<MapData>? _map;
  String? _notice;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _load(eventMapId(eventSource(widget.record)));
  }

  @override
  void didUpdateWidget(EventTriggerPanel old) {
    super.didUpdateWidget(old);
    final id = eventMapId(eventSource(widget.record));
    if (id != eventMapId(eventSource(old.record))) _load(id);
  }

  void _load(String? id) {
    _mapId = id;
    _map = id == null ? null : widget.loader.load(id);
  }

  Future<void> _choose(NarrativeEventSourceKind kind) async {
    final request = ++_request;
    if (!await widget.controller.prepare() || !mounted || request != _request) {
      return;
    }
    if (kind == NarrativeEventSourceKind.outcomeReceived) {
      final result = await chooseEventOutcome(
        context,
        widget.controller.catalog.outcomeSources,
      );
      if (!mounted || request != _request || result == null) return;
      widget.controller.setSource(
        widget.record.id,
        NarrativeEventSourceRef.outcomeReceived(result),
      );
    } else {
      setState(() {
        _choosing = kind;
        _notice = null;
      });
    }
  }

  void _accept(NarrativeEventSourceRef source) {
    if (widget.controller.setSource(widget.record.id, source)) {
      setState(() {
        _choosing = null;
        _notice = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final source = eventSource(record);
    final kind = _choosing ?? source?.kind;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        final controls = SingleChildScrollView(
          child: StudioPanel(
            compact: true,
            title: 'Type de déclencheur',
            children: [
              for (final type in eventSourceKinds)
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
              const SizedBox(height: 14),
              if (kind != NarrativeEventSourceKind.outcomeReceived) ...[
                StudioSelect(
                  label: _choosing == null
                      ? 'Consulter une carte'
                      : 'Carte de la source',
                  value: _mapId,
                  options: {
                    for (final e in widget.controller.project.maps)
                      e.id: '${e.name} · ${e.id}',
                  },
                  onChanged: (id) => setState(() => _load(id)),
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
              if (_choosing != null) ...[
                const SizedBox(height: 10),
                const StudioNotice(
                  'Choisissez une cible surlignée. Déplacez l’aperçu avec la main. Échap annule.',
                ),
                StudioButton(
                  label: 'Annuler le choix',
                  secondary: true,
                  onPressed: () => setState(() {
                    _request++;
                    _choosing = null;
                    _load(eventMapId(source));
                  }),
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
                _choosing == null
            ? EventOutcomeSummary(
                source: source,
                controller: widget.controller,
                onOpenProducer: widget.onProducer,
              )
            : _map == null
            ? const StudioPanel(
                title: 'Contexte',
                children: [
                  Text(
                    'Choisissez une carte. Sa consultation ne modifie pas le document actif.',
                  ),
                ],
              )
            : FutureBuilder<MapData>(
                future: _map,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done ||
                      snapshot.data?.id != _mapId && !snapshot.hasError) {
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
                      _choosing == null &&
                      source != null &&
                      eventMapId(source) == map.id &&
                      targetId != null &&
                      !map.entities.any((e) => e.id == targetId) &&
                      !map.triggers.any((t) => t.id == targetId);
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
                      if (missing)
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
                          chooseKind: _choosing,
                          selectableSources: _choosing == null
                              ? null
                              : widget.controller.catalog.spatialSources.options
                                    .where(
                                      (o) => o.selectable && o.source != null,
                                    )
                                    .map((o) => o.source!)
                                    .toSet(),
                          onChoose: _accept,
                          onCancel: () => setState(() {
                            _request++;
                            _choosing = null;
                            _load(eventMapId(source));
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _choosing == null
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
