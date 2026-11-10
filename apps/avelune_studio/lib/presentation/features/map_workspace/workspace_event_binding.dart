part of 'map_workspace_screen.dart';

extension _WorkspaceEventBinding on _MapWorkspaceScreenState {
  void _openEvents([String? id]) {
    unawaited(_openEventsRoute(id));
  }

  Future<void> _openEventsRoute(String? id, {bool filterSource = false}) =>
      _navigation.openEvents(id, filterSource: filterSource);

  void _openNarrativeEvent(String id) {
    unawaited(_openEventsRoute(id, filterSource: true));
  }

  Future<void> _openEventSource(NarrativeEventSourceRef source) =>
      _navigation.openEventSource(
        source,
        choose: (matches) => showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Événements de cette source'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final r in matches)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: StudioButton(
                          label: eventName(r),
                          secondary: true,
                          onPressed: () => Navigator.pop(context, r.id),
                        ),
                      ),
                    if (matches.isEmpty)
                      const Text(
                        'Aucun événement. Créez explicitement un brouillon pour cette source.',
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              StudioButton(
                label: 'Annuler',
                secondary: true,
                onPressed: () => Navigator.pop(context),
              ),
              StudioButton(
                label: 'Créer un événement',
                onPressed: () => Navigator.pop(context, 'create'),
              ),
            ],
          ),
        ),
        askName: () => askNarrativeName(context, 'Nom du nouvel événement'),
      );

  Future<String?> _locateEvent(NarrativeEventSourceRef source) =>
      _navigation.locateEventSource(source);

  Future<void> _testEvent() async {
    final events = _events;
    final record = events?.active;
    if (events == null || record == null) return;
    final mapId = eventMapId(eventSource(record));
    if (mapId == null) return;
    final problem = await launchPublishedEventVersion(
      isActive: () => mounted,
      events: events,
      scenes: _scenes,
      mapId: mapId,
      eventId: record.id,
      launch: _actions.launchMap,
    );
    if (mounted && problem != null) {
      events.error = problem;
      _changed();
    }
  }
}
