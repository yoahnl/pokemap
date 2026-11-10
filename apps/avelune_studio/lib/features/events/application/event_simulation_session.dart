import 'package:map_core/map_core_domain.dart';
import 'package:map_core/map_core.dart'
    show MapInstanceWorldState, MapInstanceRuntimeState;

import 'event_workspace_controller.dart';
import 'event_labels.dart';

class EventSimulationSession {
  EventSimulationSession(this.controller, this.eventId);

  final EventWorkspaceController controller;
  final String eventId;
  final _values = <String, NarrativeValue>{};
  final textValues = <String, String>{};
  final _consumed = <String>{};
  final _invalidValues = <String>{};
  final _localValues = <(String, String, String), bool>{};
  final _absentMaps = <String>{};
  NarrativeEventSimulationReport? report;
  String? error;

  Set<(String, String, String)> get localConditions {
    final result = <(String, String, String)>{};
    for (final record in controller.records) {
      for (final condition in eventExpression(record).leaves) {
        condition.whenTyped<void>(
          fact: (_, _, _) {},
          narrativeEventConsumed: (_, _) {},
          mapEventInstanceBoolean: (map, owner, key, _) {
            result.add((map, owner, key));
          },
        );
      }
    }
    return result;
  }

  void setFactBoolean(String id, bool value) {
    report = null;
    _values[id] = NarrativeValue.boolean(value);
  }

  void setFactText(NarrativeFactDefinition fact, String raw) {
    textValues[fact.id] = raw;
    report = null;
    try {
      _values[fact.id] = fact.valueKind == NarrativeValueKind.integer
          ? NarrativeValue.integer(int.parse(raw))
          : NarrativeValue.string(raw);
      _invalidValues.remove(fact.id);
      error = null;
    } catch (_) {
      _invalidValues.add(fact.id);
      error = 'Une valeur numérique doit être un entier.';
    }
  }

  void setMapAbsent(String id, bool absent) {
    report = null;
    absent ? _absentMaps.add(id) : _absentMaps.remove(id);
  }

  void setLocalBoolean(String mapId, String ownerId, String key, bool value) {
    report = null;
    _localValues[(mapId, ownerId, key)] = value;
  }

  void setConsumed(String id, bool consumed) {
    report = null;
    consumed ? _consumed.add(id) : _consumed.remove(id);
  }

  void run() {
    if (_invalidValues.isNotEmpty) {
      report = null;
      error = 'Corrigez les valeurs numériques avant de simuler.';
      return;
    }
    try {
      error = null;
      report = controller.simulation(
        NarrativeEventSimulationInput(
          targetEventId: eventId,
          factNarrativeValues: _values,
          consumedNarrativeEventIds: _consumed,
          mapInstanceWorldState: MapInstanceWorldState(
            instancesByMapId: {
              for (final map in controller.maps)
                if (!_absentMaps.contains(map.id))
                  map.id: MapInstanceRuntimeState(
                    instanceId: 'simulation:${map.id}',
                    eventBooleans: {
                      for (final entity in map.entities)
                        entity.id: {
                          for (final entry in _localValues.entries)
                            if (entry.key.$1 == map.id &&
                                entry.key.$2 == entity.id)
                              entry.key.$3: entry.value,
                        },
                    },
                  ),
            },
          ),
        ),
      );
    } catch (failure) {
      error = failure.toString();
    }
  }
}
