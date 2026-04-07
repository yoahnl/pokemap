// Catalogue « auteur » pour les listes déroulantes des règles runtime PNJ
// (visibilité + dialogues conditionnels).
//
// Objectif produit : proposer uniquement des choix issus du projet réel
// (steps Step Studio, chapitres Global Story, scénarios locaux, flags indexés),
// avec des libellés lisibles — pas de saisie libre d’identifiants métier.
//
// Limites honnêtes :
// - Les **flags** listés sont ceux que nous arrivons à **inférer** depuis
//   les graphes scénario, conditions d’activation, Step Studio, etc.
//   Un flag utilisé uniquement en runtime par script ad hoc peut ne pas
//   apparaître : l’UI ajoute alors une entrée « hors catalogue » pour la
//   valeur déjà persistée sur l’entité.
// - Ce fichier ne remplace pas un futur registre central de flags auteur.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../../narrative/application/global_story_studio_authoring.dart';
import '../../narrative/application/step_studio_authoring.dart';

/// Une entrée de liste : identifiant stable + libellé montré au créateur.
@immutable
class NpcRuntimePickOption {
  const NpcRuntimePickOption({
    required this.id,
    required this.pickerLabel,
  });

  final String id;

  /// Texte du menu : « nom humain (id) » ou libellé explicite.
  final String pickerLabel;
}

/// Listes précomputées pour l’inspecteur Map Entities (PNJ).
@immutable
class NpcRuntimeAuthoringCatalog {
  const NpcRuntimeAuthoringCatalog({
    required this.flags,
    required this.steps,
    required this.chapters,
    required this.cutscenes,
  });

  final List<NpcRuntimePickOption> flags;
  final List<NpcRuntimePickOption> steps;
  final List<NpcRuntimePickOption> chapters;
  final List<NpcRuntimePickOption> cutscenes;
}

/// Valeur sentinelle du menu « aucune cible sélectionnée ».
const String kNpcRuntimeRefNoneMenuId = '__npc_runtime_ref_none__';

/// Construit le catalogue à partir du manifeste projet courant.
NpcRuntimeAuthoringCatalog buildNpcRuntimeAuthoringCatalog(
  ProjectManifest project,
) {
  final flagIds = _collectIndexedFlagNames(project);
  final flags = flagIds
      .map(
        (id) => NpcRuntimePickOption(
          id: id,
          pickerLabel: '$id (état du monde)',
        ),
      )
      .toList(growable: false);

  return NpcRuntimeAuthoringCatalog(
    flags: flags,
    steps: _collectStepOptions(project),
    chapters: _collectChapterOptions(project),
    cutscenes: _collectLocalCutsceneOptions(project),
  );
}

/// Construit les ids du menu référence + option courante hors catalogue.
List<String> mergeRuntimeRefMenuIds(
  List<NpcRuntimePickOption> options,
  String? currentRefId,
) {
  final ids = <String>[
    kNpcRuntimeRefNoneMenuId,
    ...options.map((e) => e.id),
  ];
  final c = currentRefId?.trim() ?? '';
  if (c.isNotEmpty && !ids.contains(c)) {
    ids.add(c);
  }
  return ids;
}

String runtimeRefValueLabel(
  List<NpcRuntimePickOption> options,
  String menuId, {
  required String noneLabel,
  required String orphanLabel,
}) {
  if (menuId == kNpcRuntimeRefNoneMenuId || menuId.trim().isEmpty) {
    return noneLabel;
  }
  for (final o in options) {
    if (o.id == menuId) {
      return o.pickerLabel;
    }
  }
  return '$menuId — $orphanLabel';
}

List<String> _collectIndexedFlagNames(ProjectManifest project) {
  final out = <String>{};

  void addFlag(String? raw) {
    final v = raw?.trim();
    if (v != null && v.isNotEmpty) {
      out.add(v);
    }
  }

  // Flags explicitement déclarés dans project.json → globalProperties (opt-in).
  // Clé stable : documentée dans le rapport Step Studio / Map Entities.
  final declared = project.globalProperties['authoring.knownStoryFlagIds'];
  if (declared is List<dynamic>) {
    for (final e in declared) {
      addFlag(e?.toString());
    }
  }

  for (final scenario in project.scenarios) {
    _flagsFromCondition(scenario.activationCondition, out);
    for (final node in scenario.nodes) {
      addFlag(node.binding.flagName);
      _flagsFromCondition(node.payload.condition, out);
    }
  }

  for (final scenario in project.scenarios) {
    if (scenario.scope != ScenarioScope.globalStory) {
      continue;
    }
    final parse = parseStepStudioDocumentFromGlobalScenario(scenario);
    for (final step in parse.document.steps) {
      if (step.activation.mode == StepStudioActivationMode.whenFlagTrue) {
        addFlag(step.activation.flagName);
      }
      if (step.completion.mode == StepStudioCompletionMode.whenFlagTrue) {
        addFlag(step.completion.flagName);
      }
    }
  }

  final sorted = out.toList(growable: false)
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return sorted;
}

void _flagsFromCondition(ScriptCondition? c, Set<String> out) {
  if (c == null) {
    return;
  }
  switch (c.type) {
    case ScriptConditionType.flagIsSet:
    case ScriptConditionType.flagIsUnset:
      final v = c.params[ScriptConditionParams.flagName]?.trim();
      if (v != null && v.isNotEmpty) {
        out.add(v);
      }
      break;
    default:
      break;
  }
  for (final child in c.children) {
    _flagsFromCondition(child, out);
  }
}

List<NpcRuntimePickOption> _collectStepOptions(ProjectManifest project) {
  final out = <NpcRuntimePickOption>[];
  final seen = <String>{};

  for (final scenario in project.scenarios) {
    if (scenario.scope != ScenarioScope.globalStory) {
      continue;
    }
    final parse = parseStepStudioDocumentFromGlobalScenario(scenario);
    for (final step in parse.document.steps) {
      final id = step.id.trim();
      if (id.isEmpty || seen.contains(id)) {
        continue;
      }
      seen.add(id);
      final name = step.name.trim().isEmpty ? id : step.name.trim();
      out.add(
        NpcRuntimePickOption(
          id: id,
          pickerLabel: '$name ($id)',
        ),
      );
    }
  }
  out.sort(
    (a, b) => a.pickerLabel.toLowerCase().compareTo(b.pickerLabel.toLowerCase()),
  );
  return out;
}

List<NpcRuntimePickOption> _collectChapterOptions(ProjectManifest project) {
  final out = <NpcRuntimePickOption>[];
  final seen = <String>{};

  for (final scenario in project.scenarios) {
    if (scenario.scope != ScenarioScope.globalStory) {
      continue;
    }
    final raw = scenario.metadata[kGlobalStoryStudioDocumentMetadataKey];
    if (raw == null || raw.trim().isEmpty) {
      continue;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        continue;
      }
      final doc = GlobalStoryStudioDocument.fromJson(decoded);
      for (final ch in doc.chapters) {
        final id = ch.id.trim();
        if (id.isEmpty || seen.contains(id)) {
          continue;
        }
        seen.add(id);
        final name = ch.name.trim().isEmpty ? id : ch.name.trim();
        out.add(
          NpcRuntimePickOption(
            id: id,
            pickerLabel: '$name ($id)',
          ),
        );
      }
    } catch (_) {
      // JSON invalide : on ignore ce scénario.
    }
  }
  out.sort(
    (a, b) => a.pickerLabel.toLowerCase().compareTo(b.pickerLabel.toLowerCase()),
  );
  return out;
}

List<NpcRuntimePickOption> _collectLocalCutsceneOptions(
  ProjectManifest project,
) {
  final out = <NpcRuntimePickOption>[];

  for (final s in project.scenarios) {
    if (s.scope != ScenarioScope.localEventFlow) {
      continue;
    }
    final name = s.name.trim().isEmpty ? s.id : s.name.trim();
    out.add(
      NpcRuntimePickOption(
        id: s.id,
        pickerLabel: '$name (${s.id})',
      ),
    );
  }
  out.sort(
    (a, b) => a.pickerLabel.toLowerCase().compareTo(b.pickerLabel.toLowerCase()),
  );
  return out;
}
