import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'event_labels.dart';
import 'event_map_loader.dart';

class EventSourceIdentity extends StatefulWidget {
  const EventSourceIdentity({
    super.key,
    required this.source,
    required this.loader,
  });
  final NarrativeEventSourceRef source;
  final EventMapLoader loader;
  @override
  State<EventSourceIdentity> createState() => _EventSourceIdentityState();
}

class _EventSourceIdentityState extends State<EventSourceIdentity> {
  Future<MapData>? _map;
  void _load() {
    final id = eventMapId(widget.source);
    _map = id == null ? null : widget.loader.load(id);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(EventSourceIdentity old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source) _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<MapData>(
    future: _map,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Text('Chargement de la source…');
      }
      if (snapshot.hasError) {
        return const Text('Source indisponible · carte à réparer');
      }
      final map = snapshot.data;
      if (map == null) return const Text('Source à charger…');
      final id = eventTargetId(widget.source);
      final entities = map.entities.where((e) => e.id == id).toList();
      final triggers = map.triggers.where((t) => t.id == id).toList();
      if (id == null) return const Text('Toute la carte · à son entrée');
      final matches =
          widget.source.kind == NarrativeEventSourceKind.entityInteract
          ? entities.length
          : triggers.length;
      if (matches != 1) {
        return Text(
          '${matches == 0 ? 'Source absente' : 'Source ambiguë'} · $id',
        );
      }
      final entitySource =
          widget.source.kind == NarrativeEventSourceKind.entityInteract;
      final position = entitySource
          ? entities.single.pos
          : triggers.single.area.pos;
      final name = entitySource ? entities.single.name : triggers.single.name;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? eventKindLabel(widget.source.kind) : name,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            'Position : (${position.x}, ${position.y})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    },
  );
}
