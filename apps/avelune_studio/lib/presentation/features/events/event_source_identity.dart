import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'event_labels.dart';
import 'package:avelune_studio/features/events/application/event_map_loader.dart';
import 'package:avelune_studio/features/events/application/event_source_description.dart';

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
        return const Text(eventSourceMapToRepair);
      }
      final map = snapshot.data;
      if (map == null) return const Text('Source à charger…');
      final description = describeEventSource(
        source: widget.source,
        map: map,
        project: widget.loader.workspace.project,
      );
      final position = description.position;
      if (position == null) return Text(description.title);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description.title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(position, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
    },
  );
}
