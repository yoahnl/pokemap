import '../models/map_event_definition.dart';
import '../models/script_conditions.dart';
import 'event_builder_contract.dart';

/// Lit une page de [MapEventDefinition] comme contrat Event Builder MVP.
///
/// Cette fonction ne migre rien et ne supprime rien. Elle traduit seulement le
/// sous-ensemble no-code supporté par NS-EVENT-02, puis transporte les limites
/// legacy sous forme de diagnostics.
EventBuilderContractView readEventBuilderContractFromMapEvent(
  MapEventDefinition event, {
  int? pageNumber,
}) {
  final page = _selectPage(event, pageNumber: pageNumber);
  final source = EventBuilderSourceBinding(
    eventId: event.id,
    eventTitle: event.title,
    eventType: event.type,
    position: event.position,
  );
  final trigger = EventBuilderTriggerBinding(
    kind: _triggerKindForEventType(event.type),
    source: source,
  );
  final diagnostics = <EventBuilderContractDiagnostic>[];
  final conditions = _readConditionBindings(
    page.condition,
    diagnostics,
    path: 'page.condition',
  );
  final sceneAction = _readSceneAction(page.sceneTarget);
  final behavior = _readBehaviorBinding(page.metadata, diagnostics);

  if (sceneAction == null) {
    diagnostics.add(
      EventBuilderContractDiagnostic(
        severity: EventBuilderContractDiagnosticSeverity.error,
        kind: EventBuilderContractDiagnosticKind.missingSceneAction,
        message: 'Event Builder MVP requires a Scene action.',
        path: 'page.sceneTarget',
      ),
    );
  }
  if (page.script != null) {
    diagnostics.add(
      EventBuilderContractDiagnostic(
        severity: EventBuilderContractDiagnosticSeverity.warning,
        kind: EventBuilderContractDiagnosticKind.unsupportedLegacyScript,
        message: 'Legacy script references are preserved but not part of the '
            'Event Builder MVP contract.',
        path: 'page.script',
        referencedId: page.script?.scriptId,
      ),
    );
  }
  if ((page.message ?? '').trim().isNotEmpty) {
    diagnostics.add(
      EventBuilderContractDiagnostic(
        severity: EventBuilderContractDiagnosticSeverity.warning,
        kind: EventBuilderContractDiagnosticKind.unsupportedLegacyMessage,
        message: 'Legacy page messages are preserved but not part of the '
            'Event Builder MVP contract.',
        path: 'page.message',
      ),
    );
  }

  return EventBuilderContractView(
    source: source,
    trigger: trigger,
    conditions: conditions,
    sceneAction: sceneAction,
    behavior: behavior,
    worldImpactPreviews: _buildWorldImpactPreviews(
      source: source,
      behavior: behavior,
    ),
    diagnostics: diagnostics,
    legacyConditionToPreserve: conditions.isEmpty ? page.condition : null,
  );
}

EventBuilderContractView createEventBuilderDraftForMapEvent(
  MapEventDefinition event, {
  int? pageNumber,
}) {
  return readEventBuilderContractFromMapEvent(
    event,
    pageNumber: pageNumber,
  );
}

/// Applique un contrat Event Builder sur une page existante.
///
/// La fonction écrit seulement les surfaces MVP : [MapEventSceneTarget],
/// [ScriptCondition] compilable et metadata typée Event Builder. Les champs
/// legacy tels que `script` ou `message` sont volontairement préservés.
MapEventDefinition applyEventBuilderContractToMapEvent(
  MapEventDefinition event,
  EventBuilderContractView contract, {
  int? pageNumber,
}) {
  final pageIndex = _selectPageIndex(event, pageNumber: pageNumber);
  final page = event.pages[pageIndex];
  final compiled = compileEventBuilderConditionsToScriptCondition(
    contract.conditions,
  );
  if (compiled.hasErrors) {
    throw UnsupportedError(
      'Event Builder contract contains conditions that cannot be compiled '
      'to ScriptCondition in NS-EVENT-02.',
    );
  }

  final nextCondition = compiled.condition ??
      (contract.conditions.isEmpty ? contract.legacyConditionToPreserve : null);
  final nextPage = page.copyWith(
    sceneTarget: contract.sceneAction == null
        ? null
        : MapEventSceneTarget(sceneId: contract.sceneAction!.sceneId),
    condition: nextCondition,
    metadata: _writeBehaviorMetadata(
      page.metadata,
      contract.behavior,
    ),
  );
  final nextPages = List<MapEventPage>.from(event.pages, growable: false);
  nextPages[pageIndex] = nextPage;
  return event.copyWith(pages: nextPages);
}

EventBuilderContractView updateEventBuilderTrigger(
  EventBuilderContractView contract,
  EventBuilderTriggerBinding trigger,
) {
  return contract.copyWith(
    source: trigger.source,
    trigger: trigger,
  );
}

EventBuilderContractView updateEventBuilderSceneAction(
  EventBuilderContractView contract,
  EventBuilderSceneActionBinding action,
) {
  return contract.copyWith(sceneAction: action);
}

EventBuilderContractView addEventBuilderCondition(
  EventBuilderContractView contract,
  EventBuilderConditionBinding condition,
) {
  return contract.copyWith(
    conditions: [...contract.conditions, condition],
    clearLegacyConditionToPreserve: true,
  );
}

EventBuilderContractView removeEventBuilderCondition(
  EventBuilderContractView contract,
  int index,
) {
  if (index < 0 || index >= contract.conditions.length) {
    throw RangeError.index(index, contract.conditions, 'index');
  }
  final nextConditions = contract.conditions.toList(growable: true)
    ..removeAt(index);
  return contract.copyWith(
    conditions: nextConditions,
    clearLegacyConditionToPreserve: true,
  );
}

EventBuilderContractView updateEventBuilderBehavior(
  EventBuilderContractView contract,
  EventBuilderBehaviorBinding behavior,
) {
  return contract.copyWith(behavior: behavior);
}

MapEventPage _selectPage(
  MapEventDefinition event, {
  required int? pageNumber,
}) {
  final pageIndex = _selectPageIndex(event, pageNumber: pageNumber);
  return event.pages[pageIndex];
}

int _selectPageIndex(
  MapEventDefinition event, {
  required int? pageNumber,
}) {
  if (event.pages.isEmpty) {
    throw ArgumentError.value(event.id, 'event', 'Map event has no pages.');
  }
  if (pageNumber == null) {
    var selectedIndex = 0;
    for (var i = 1; i < event.pages.length; i++) {
      if (event.pages[i].pageNumber < event.pages[selectedIndex].pageNumber) {
        selectedIndex = i;
      }
    }
    return selectedIndex;
  }
  final index = event.pages.indexWhere((page) => page.pageNumber == pageNumber);
  if (index < 0) {
    throw ArgumentError.value(
      pageNumber,
      'pageNumber',
      'Map event page not found.',
    );
  }
  return index;
}

EventBuilderTriggerKind _triggerKindForEventType(MapEventType type) {
  return switch (type) {
    MapEventType.triggerZone => EventBuilderTriggerKind.zoneEnter,
    MapEventType.actor ||
    MapEventType.object ||
    MapEventType.effect =>
      EventBuilderTriggerKind.interaction,
  };
}

EventBuilderSceneActionBinding? _readSceneAction(
  MapEventSceneTarget? sceneTarget,
) {
  final sceneId = sceneTarget?.sceneId.trim();
  if (sceneId == null || sceneId.isEmpty) {
    return null;
  }
  return EventBuilderSceneActionBinding(sceneId: sceneId);
}

EventBuilderBehaviorBinding _readBehaviorBinding(
  Map<String, String> metadata,
  List<EventBuilderContractDiagnostic> diagnostics,
) {
  final raw = metadata[EventBuilderMetadataKeys.reusePolicy]?.trim();
  if (raw == null || raw.isEmpty) {
    return const EventBuilderBehaviorBinding.oneShot();
  }
  for (final policy in EventBuilderReusePolicy.values) {
    if (policy.name == raw) {
      return EventBuilderBehaviorBinding(reusePolicy: policy);
    }
  }
  diagnostics.add(
    EventBuilderContractDiagnostic(
      severity: EventBuilderContractDiagnosticSeverity.warning,
      kind: EventBuilderContractDiagnosticKind.metadataMalformed,
      message: 'Unknown Event Builder reuse policy "$raw"; defaulting to '
          'oneShot.',
      path: 'page.metadata.${EventBuilderMetadataKeys.reusePolicy}',
    ),
  );
  return const EventBuilderBehaviorBinding.oneShot();
}

Map<String, String> _writeBehaviorMetadata(
  Map<String, String> current,
  EventBuilderBehaviorBinding behavior,
) {
  return Map<String, String>.unmodifiable({
    ...current,
    EventBuilderMetadataKeys.schemaVersion:
        EventBuilderMetadataKeys.currentSchemaVersion,
    EventBuilderMetadataKeys.reusePolicy: behavior.reusePolicy.name,
  });
}

List<EventBuilderConditionBinding> _readConditionBindings(
  ScriptCondition? condition,
  List<EventBuilderContractDiagnostic> diagnostics, {
  required String path,
}) {
  if (condition == null) {
    return const <EventBuilderConditionBinding>[];
  }
  final bindings = <EventBuilderConditionBinding>[];
  _appendConditionBindings(condition, bindings, diagnostics, path: path);
  return List<EventBuilderConditionBinding>.unmodifiable(bindings);
}

void _appendConditionBindings(
  ScriptCondition condition,
  List<EventBuilderConditionBinding> bindings,
  List<EventBuilderContractDiagnostic> diagnostics, {
  required String path,
}) {
  switch (condition.type) {
    case ScriptConditionType.flagIsSet:
      final flagName = condition.params[ScriptConditionParams.flagName];
      if ((flagName ?? '').trim().isNotEmpty) {
        bindings.add(EventBuilderConditionBinding.factIsTrue(flagName!));
        return;
      }
    case ScriptConditionType.flagIsUnset:
      final flagName = condition.params[ScriptConditionParams.flagName];
      if ((flagName ?? '').trim().isNotEmpty) {
        bindings.add(EventBuilderConditionBinding.factIsFalse(flagName!));
        return;
      }
    case ScriptConditionType.eventIsConsumed:
      final eventId = condition.params[ScriptConditionParams.eventId];
      if ((eventId ?? '').trim().isNotEmpty) {
        bindings.add(EventBuilderConditionBinding.eventConsumed(eventId!));
        return;
      }
    case ScriptConditionType.not:
      final child =
          condition.children.length == 1 ? condition.children.single : null;
      if (child?.type == ScriptConditionType.eventIsConsumed) {
        final eventId = child?.params[ScriptConditionParams.eventId];
        if ((eventId ?? '').trim().isNotEmpty) {
          bindings.add(EventBuilderConditionBinding.eventNotConsumed(eventId!));
          return;
        }
      }
    case ScriptConditionType.allOf:
      for (var i = 0; i < condition.children.length; i++) {
        _appendConditionBindings(
          condition.children[i],
          bindings,
          diagnostics,
          path: '$path.children[$i]',
        );
      }
      return;
    case ScriptConditionType.anyOf:
    case ScriptConditionType.variableEquals:
    case ScriptConditionType.variableGreaterThan:
    case ScriptConditionType.variableLessThan:
    case ScriptConditionType.fieldAbilityUnlocked:
    case ScriptConditionType.partyHasMove:
    case ScriptConditionType.partyHasUsableMove:
    case ScriptConditionType.playerOnMap:
      break;
  }

  diagnostics.add(
    EventBuilderContractDiagnostic(
      severity: EventBuilderContractDiagnosticSeverity.warning,
      kind: EventBuilderContractDiagnosticKind.unsupportedLegacyCondition,
      message: 'Existing ScriptCondition is preserved but is not part of '
          'the Event Builder MVP no-code subset.',
      path: path,
    ),
  );
}

List<EventBuilderWorldImpactPreview> _buildWorldImpactPreviews({
  required EventBuilderSourceBinding source,
  required EventBuilderBehaviorBinding behavior,
}) {
  if (behavior.reusePolicy != EventBuilderReusePolicy.oneShot) {
    return const <EventBuilderWorldImpactPreview>[];
  }
  return [
    EventBuilderWorldImpactPreview(
      kind: EventBuilderWorldImpactKind.consumedEvent,
      sourceId: source.eventId,
      label: source.eventTitle.isEmpty ? source.eventId : source.eventTitle,
      reason: 'A one-shot event can drive World Rules through consumed event '
          'state after the Scene succeeds.',
    ),
  ];
}
