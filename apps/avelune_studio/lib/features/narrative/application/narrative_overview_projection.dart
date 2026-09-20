import 'package:map_core/map_core_domain.dart';

import 'interaction_edit_session.dart';
import 'narrative_interaction.dart';
import 'narrative_interaction_reader.dart';
import 'narrative_overview.dart';
import 'narrative_overview_context.dart';
import 'narrative_overview_references.dart';
import 'narrative_workspace_controller.dart';

NarrativeOverview buildNarrativeOverview(
  NarrativeWorkspaceController controller,
) {
  final project = controller.project;
  final context = NarrativeOverviewContext(
    project,
    controller.stories,
    controller.facts,
    controller.workspace.documents.values.map((d) => d.current),
  );
  final records = {
    for (final r in project.eventRegistry?.records ?? <NarrativeEventRecord>[])
      r.id: r,
  };
  final sessions = {
    for (final s in controller.sessions.values) s.current.interaction.id: s,
  };
  for (final s in sessions.values) {
    context.dialogueNames[s.current.dialogue.entry.id] =
        s.current.dialogue.entry.name;
    context.eventNames[s.current.interaction.id] = s.current.interaction.name;
  }
  final interactions = [
    for (final id in {...records.keys, ...sessions.keys})
      _interaction(context, id, records[id], sessions[id]),
  ];
  final steps = <String, List<NarrativeOverviewInteraction>>{};
  final facts = <String, List<NarrativeOverviewInteraction>>{};
  for (final item in interactions) {
    for (final reference in item.references) {
      if (reference.kind == NarrativeOverviewReferenceKind.step) {
        steps.putIfAbsent(reference.id, () => []).add(item);
      }
      if (reference.kind == NarrativeOverviewReferenceKind.fact) {
        facts.putIfAbsent(reference.id, () => []).add(item);
      }
    }
  }
  return NarrativeOverview(
    stories: context.stories,
    facts: context.facts,
    interactions: interactions,
    stepsById: context.steps,
    stepLinks: steps,
    factLinks: facts,
    stepReferences: context.stepReferences,
    dirtyCount:
        controller.pendingFacts.length +
        controller.pendingStories.length +
        controller.pendingStoryDeletions.length +
        sessions.values.where((s) => s.dirty).length,
  );
}

NarrativeOverviewInteraction _interaction(
  NarrativeOverviewContext context,
  String id,
  NarrativeEventRecord? record,
  InteractionEditSession? session,
) {
  final definition = record?.definitionOrNull;
  final pending = record?.draftOrNull;
  final local = session?.current.interaction;
  final source = local?.source ?? definition?.source ?? pending?.source;
  final location = context.source(source);
  final sceneId = local?.sceneId ?? definition?.sceneId ?? pending?.sceneId;
  final scene = sceneId == null ? null : context.scenes[sceneId];
  final cinematicIds = {
    for (final node in scene?.graph.nodes ?? <SceneNode>[])
      if (node.payload case SceneCinematicPayload(:final cinematicId))
        cinematicId,
  };
  final missingStructure =
      scene == null ||
      cinematicIds.any((id) => !context.cinematics.containsKey(id));
  NarrativeInteractionDraft? compatible = local;
  if (compatible == null && record != null && scene != null) {
    compatible = readStudioInteraction(
      record,
      context.project.copyWith(
        scenes: [scene],
        cinematics: [for (final id in cinematicIds) ?context.cinematics[id]],
      ),
    );
  }
  final advanced =
      (compatible == null && !missingStructure) || session?.editable == false;
  final references = NarrativeOverviewReferences(context);
  final rawConditions =
      local?.conditions ?? definition?.conditions ?? pending?.conditions ?? [];
  final conditions = [
    for (final condition in rawConditions) references.condition(condition),
  ];
  final consequences = <String>[];
  if (local != null) {
    references.known(
      NarrativeOverviewReferenceKind.scene,
      local.sceneId,
      local.name,
    );
    consequences.add(
      'Afficher le dialogue « ${references.add(NarrativeOverviewReferenceKind.dialogue, local.dialogueId)} »',
    );
    for (final step in local.steps) {
      consequences.add(references.step(step));
    }
    for (final branch in local.branches.values) {
      for (final step in branch) {
        consequences.add('Selon le choix : ${references.step(step)}');
      }
    }
  } else {
    if (sceneId != null) {
      references.add(NarrativeOverviewReferenceKind.scene, sceneId);
    }
    if (scene != null) references.scene(scene);
    if (compatible != null) {
      consequences.add(
        'Afficher le dialogue « ${context.dialogueNames[compatible.dialogueId] ?? compatible.dialogueId} »',
      );
      for (final step in compatible.steps) {
        consequences.add(references.step(step));
      }
      for (final branch in compatible.branches.values) {
        for (final step in branch) {
          consequences.add('Selon le choix : ${references.step(step)}');
        }
      }
    }
  }
  for (final step in context.sceneSteps[sceneId] ?? <String>{}) {
    references.add(NarrativeOverviewReferenceKind.step, step);
  }
  final missing = [
    if (location.missing != null) location.missing!,
    for (final ref in references.values.where((r) => r.missing))
      'Référence absente : ${ref.label}',
  ];
  return NarrativeOverviewInteraction(
    id: id,
    name:
        local?.name ??
        definition?.name ??
        pending?.name ??
        'Interaction avancée',
    mapId: location.mapId,
    mapLabel:
        context.mapNames[location.mapId] ??
        (location.mapId == null
            ? 'Sans carte source'
            : 'Carte absente · ${location.mapId}'),
    sourceLabel: location.label,
    whenText: location.when,
    source: source,
    record: record,
    session: session,
    draft: compatible,
    dirty: session?.dirty ?? false,
    advanced: advanced,
    conditions: advanced && conditions.isNotEmpty
        ? ['Conditions avancées — analyse détaillée indisponible']
        : conditions,
    consequences: advanced
        ? ['Analyse détaillée indisponible']
        : compatible == null
        ? ['Structure narrative indisponible']
        : consequences,
    references: references.values.toList(),
    missingReferences: missing,
  );
}
