import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'step_studio_authoring.dart';

/// Version de schéma du document Global Story Studio v1.1.
///
/// v1.1 ajoute le concept de **chapitre / arc narratif**:
/// - les steps sont désormais groupées en chapitres pour une lecture macro;
/// - un chapitre par défaut est créé automatiquement pour la rétrocompatibilité;
/// - le document reste strictement "macro": il ne décrit PAS la logique locale.
///
/// Ce document a une responsabilité strictement "macro":
/// - chapitres / arcs narratifs;
/// - liens entre steps;
/// - point d'entrée global;
/// - type de sortie (linéaire / branchement / convergence).
///
/// Il NE remplace PAS la logique métier locale d'une step, qui reste portée
/// par [StepStudioDocument].
const String kGlobalStoryStudioSchemaVersion = 'global_story_studio_v1.1';

/// Clé metadata de version du document Global Story Studio.
const String kGlobalStoryStudioSchemaMetadataKey =
    'authoring.globalStoryStudioSchema';

/// Clé metadata JSON du document Global Story Studio.
const String kGlobalStoryStudioDocumentMetadataKey =
    'authoring.globalStoryStudioDocument';

/// Type de sortie macro pour une step dans la structure globale.
///
/// Important:
/// - ce mode décrit la structure de progression globale;
/// - il ne décrit pas la mise en scène locale (cutscene).
enum GlobalStoryStepExitMode {
  linear,
  branchExclusive,
  branchConditional,
  converge,
}

String globalStoryStepExitModeLabel(GlobalStoryStepExitMode mode) {
  return switch (mode) {
    GlobalStoryStepExitMode.linear => 'Linéaire',
    GlobalStoryStepExitMode.branchExclusive => 'Branche exclusive',
    GlobalStoryStepExitMode.branchConditional => 'Branche conditionnelle',
    GlobalStoryStepExitMode.converge => 'Convergence',
  };
}

/// Lien de transition macro entre 2 steps.
///
/// - [toStepId] est la destination.
/// - [conditionLabel] et [requiredOutcomeId] sont optionnels et servent
///   surtout en mode conditionnel pour rendre le flux lisible côté no-code.
@immutable
class GlobalStoryStepLink {
  const GlobalStoryStepLink({
    required this.toStepId,
    this.conditionLabel,
    this.requiredOutcomeId,
  });

  final String toStepId;
  final String? conditionLabel;
  final String? requiredOutcomeId;

  GlobalStoryStepLink copyWith({
    String? toStepId,
    Object? conditionLabel = _unset,
    Object? requiredOutcomeId = _unset,
  }) {
    return GlobalStoryStepLink(
      toStepId: toStepId ?? this.toStepId,
      conditionLabel: identical(conditionLabel, _unset)
          ? this.conditionLabel
          : conditionLabel as String?,
      requiredOutcomeId: identical(requiredOutcomeId, _unset)
          ? this.requiredOutcomeId
          : requiredOutcomeId as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'toStepId': toStepId,
        'conditionLabel': conditionLabel,
        'requiredOutcomeId': requiredOutcomeId,
      };

  factory GlobalStoryStepLink.fromJson(Map<String, dynamic> json) {
    return GlobalStoryStepLink(
      toStepId: _trimOrEmpty(json['toStepId']),
      conditionLabel: _trimOrNull(json['conditionLabel']),
      requiredOutcomeId: _trimOrNull(json['requiredOutcomeId']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GlobalStoryStepLink &&
        other.toStepId == toStepId &&
        other.conditionLabel == conditionLabel &&
        other.requiredOutcomeId == requiredOutcomeId;
  }

  @override
  int get hashCode => Object.hash(toStepId, conditionLabel, requiredOutcomeId);
}

/// Chapitre / arc narratif dans la structure globale du jeu.
///
/// Rôle produit:
/// - grouper visuellement les steps en arcs narratifs lisibles;
/// - donner une hiérarchie de haut niveau à la structure du jeu;
/// - rester un concept "macro": un chapitre ne décrit PAS la logique locale.
///
/// Contraintes:
/// - les `stepIds` sont ordonnés et référencent des steps du Step Studio;
/// - une step ne peut appartenir qu'à UN seul chapitre;
/// - un chapitre peut être vide (prêt à recevoir des steps futures).
@immutable
class GlobalStoryChapter {
  const GlobalStoryChapter({
    required this.id,
    required this.name,
    required this.description,
    required this.stepIds,
    required this.order,
  });

  final String id;
  final String name;
  final String description;
  final List<String> stepIds;
  final int order;

  GlobalStoryChapter copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? stepIds,
    int? order,
  }) {
    return GlobalStoryChapter(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      stepIds: stepIds ?? this.stepIds,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'stepIds': stepIds,
        'order': order,
      };

  factory GlobalStoryChapter.fromJson(Map<String, dynamic> json) {
    final stepIdsJson = (json['stepIds'] as List<dynamic>? ?? const []);
    return GlobalStoryChapter(
      id: _trimOrEmpty(json['id']),
      name: _trimOrEmpty(json['name']),
      description: _trimOrEmpty(json['description']),
      stepIds: stepIdsJson
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GlobalStoryChapter &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        listEquals(other.stepIds, stepIds) &&
        other.order == order;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, Object.hashAll(stepIds), order);
}

/// Noeud macro du scénario global: une step + sa logique de sortie.
@immutable
class GlobalStoryStepNode {
  const GlobalStoryStepNode({
    required this.stepId,
    this.exitMode = GlobalStoryStepExitMode.linear,
    this.links = const <GlobalStoryStepLink>[],
  });

  final String stepId;
  final GlobalStoryStepExitMode exitMode;
  final List<GlobalStoryStepLink> links;

  GlobalStoryStepNode copyWith({
    String? stepId,
    GlobalStoryStepExitMode? exitMode,
    List<GlobalStoryStepLink>? links,
  }) {
    return GlobalStoryStepNode(
      stepId: stepId ?? this.stepId,
      exitMode: exitMode ?? this.exitMode,
      links: links ?? this.links,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'stepId': stepId,
        'exitMode': exitMode.name,
        'links': links.map((entry) => entry.toJson()).toList(growable: false),
      };

  factory GlobalStoryStepNode.fromJson(Map<String, dynamic> json) {
    final linkJson = (json['links'] as List<dynamic>? ?? const []);
    return GlobalStoryStepNode(
      stepId: _trimOrEmpty(json['stepId']),
      exitMode: _parseGlobalStoryStepExitMode(
        json['exitMode']?.toString(),
        fallback: GlobalStoryStepExitMode.linear,
      ),
      links: linkJson
          .whereType<Map<String, dynamic>>()
          .map(GlobalStoryStepLink.fromJson)
          .where((entry) => entry.toStepId.trim().isNotEmpty)
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GlobalStoryStepNode &&
        other.stepId == stepId &&
        other.exitMode == exitMode &&
        listEquals(other.links, links);
  }

  @override
  int get hashCode => Object.hash(stepId, exitMode, Object.hashAll(links));
}

/// Document canonique du Global Story Studio.
///
/// Rappel produit:
/// - il n'y a qu'UN seul scénario global pour le jeu;
/// - ce document encode uniquement la structure macro de progression;
/// - les chapitres groupent les steps en arcs narratifs lisibles.
@immutable
class GlobalStoryStudioDocument {
  const GlobalStoryStudioDocument({
    required this.globalStoryScenarioId,
    required this.entryStepId,
    required this.nodes,
    this.chapters = const <GlobalStoryChapter>[],
    this.schemaVersion = kGlobalStoryStudioSchemaVersion,
  });

  final String schemaVersion;
  final String globalStoryScenarioId;
  final String entryStepId;
  final List<GlobalStoryStepNode> nodes;

  /// Chapitres / arcs narratifs du scénario global.
  ///
  /// - Si vide, le chapitre par défaut "Histoire principale" sera dérivé
  ///   automatiquement lors de la normalisation.
  /// - Les `stepIds` de tous les chapitres combinés doivent correspondre
  ///   aux steps du `StepStudioDocument`.
  final List<GlobalStoryChapter> chapters;

  GlobalStoryStudioDocument copyWith({
    String? schemaVersion,
    String? globalStoryScenarioId,
    String? entryStepId,
    List<GlobalStoryStepNode>? nodes,
    Object? chapters = _unset,
  }) {
    return GlobalStoryStudioDocument(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      globalStoryScenarioId:
          globalStoryScenarioId ?? this.globalStoryScenarioId,
      entryStepId: entryStepId ?? this.entryStepId,
      nodes: nodes ?? this.nodes,
      chapters: identical(chapters, _unset)
          ? this.chapters
          : chapters as List<GlobalStoryChapter>,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'globalStoryScenarioId': globalStoryScenarioId,
        'entryStepId': entryStepId,
        'nodes': nodes.map((entry) => entry.toJson()).toList(growable: false),
        'chapters':
            chapters.map((entry) => entry.toJson()).toList(growable: false),
      };

  String toMetadataJson() => jsonEncode(toJson());

  factory GlobalStoryStudioDocument.fromJson(Map<String, dynamic> json) {
    final nodeJson = (json['nodes'] as List<dynamic>? ?? const []);
    final chapterJson = (json['chapters'] as List<dynamic>? ?? const []);
    return GlobalStoryStudioDocument(
      schemaVersion:
          _trimOrNull(json['schemaVersion']) ?? kGlobalStoryStudioSchemaVersion,
      globalStoryScenarioId:
          _trimOrNull(json['globalStoryScenarioId']) ?? 'global_story',
      entryStepId: _trimOrEmpty(json['entryStepId']),
      nodes: nodeJson
          .whereType<Map<String, dynamic>>()
          .map(GlobalStoryStepNode.fromJson)
          .where((entry) => entry.stepId.trim().isNotEmpty)
          .toList(growable: false),
      chapters: chapterJson
          .whereType<Map<String, dynamic>>()
          .map(GlobalStoryChapter.fromJson)
          .where((entry) => entry.id.trim().isNotEmpty)
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GlobalStoryStudioDocument &&
        other.schemaVersion == schemaVersion &&
        other.globalStoryScenarioId == globalStoryScenarioId &&
        other.entryStepId == entryStepId &&
        listEquals(other.nodes, nodes) &&
        listEquals(other.chapters, chapters);
  }

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        globalStoryScenarioId,
        entryStepId,
        Object.hashAll(nodes),
        Object.hashAll(chapters),
      );
}

/// Résultat de parse du document Global Story Studio.
@immutable
class GlobalStoryStudioParseResult {
  const GlobalStoryStudioParseResult({
    required this.document,
    required this.warnings,
    required this.usedLegacyFallback,
  });

  final GlobalStoryStudioDocument document;
  final List<String> warnings;
  final bool usedLegacyFallback;
}

/// Parse la structure macro du scénario global depuis la metadata.
///
/// Règle de fallback:
/// - si le document n'existe pas (ou est invalide), on reconstruit un
///   flux linéaire à partir de l'ordre des steps du [stepDocument].
GlobalStoryStudioParseResult parseGlobalStoryStudioDocumentFromGlobalScenario(
  ScenarioAsset scenario, {
  required StepStudioDocument stepDocument,
}) {
  final warnings = <String>[];

  if (scenario.scope != ScenarioScope.globalStory) {
    warnings.add(
      'Le Global Story Studio v1 attend un scénario de scope "globalStory".',
    );
  }

  final rawDocument = scenario.metadata[kGlobalStoryStudioDocumentMetadataKey];
  if (rawDocument != null && rawDocument.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(rawDocument);
      if (decoded is Map<String, dynamic>) {
        final parsed = GlobalStoryStudioDocument.fromJson(decoded);
        final normalized = normalizeGlobalStoryStudioDocument(
          document: parsed.copyWith(globalStoryScenarioId: scenario.id),
          stepDocument: stepDocument,
        );
        return GlobalStoryStudioParseResult(
          document: normalized,
          warnings: computeGlobalStoryStudioDiagnostics(
            document: normalized,
            stepDocument: stepDocument,
            existingWarnings: warnings,
          ),
          usedLegacyFallback: false,
        );
      }
      warnings.add(
        'Le document Global Story Studio metadata n\'est pas un objet JSON valide.',
      );
    } catch (error) {
      warnings.add(
        'Impossible de lire authoring.globalStoryStudioDocument: $error',
      );
    }
  }

  final fallback = createDefaultGlobalStoryStudioDocument(
    globalStoryScenarioId: scenario.id,
    stepDocument: stepDocument,
  );
  return GlobalStoryStudioParseResult(
    document: fallback,
    warnings: computeGlobalStoryStudioDiagnostics(
      document: fallback,
      stepDocument: stepDocument,
      existingWarnings: warnings,
    ),
    usedLegacyFallback: true,
  );
}

/// Applique le document macro Global Story sur le scénario global canonique.
///
/// Cette mutation reste non destructive:
/// - on conserve le graphe runtime existant;
/// - on ajoute/met à jour la metadata d'authoring no-code.
ScenarioAsset applyGlobalStoryStudioDocumentToGlobalScenario(
  ScenarioAsset scenario,
  GlobalStoryStudioDocument document, {
  required StepStudioDocument stepDocument,
}) {
  final normalized = normalizeGlobalStoryStudioDocument(
    document: document.copyWith(globalStoryScenarioId: scenario.id),
    stepDocument: stepDocument,
  );
  final nextMetadata = <String, String>{
    ...scenario.metadata,
    kGlobalStoryStudioSchemaMetadataKey: kGlobalStoryStudioSchemaVersion,
    kGlobalStoryStudioDocumentMetadataKey: normalized.toMetadataJson(),
  };
  return scenario.copyWith(metadata: nextMetadata);
}

/// Fabrique un flux global linéaire simple à partir des steps existantes.
///
/// Un chapitre par défaut "Histoire principale" est créé automatiquement
/// pour que la structure soit immédiatement lisible dans l'UI.
GlobalStoryStudioDocument createDefaultGlobalStoryStudioDocument({
  required String globalStoryScenarioId,
  required StepStudioDocument stepDocument,
}) {
  final orderedSteps = stepDocument.steps.toList(growable: false)
    ..sort((a, b) => a.order.compareTo(b.order));
  if (orderedSteps.isEmpty) {
    return GlobalStoryStudioDocument(
      globalStoryScenarioId: globalStoryScenarioId,
      entryStepId: '',
      nodes: const <GlobalStoryStepNode>[],
      chapters: const <GlobalStoryChapter>[],
    );
  }

  final nodes = <GlobalStoryStepNode>[];
  final allStepIds = <String>[];
  for (var index = 0; index < orderedSteps.length; index++) {
    final step = orderedSteps[index];
    allStepIds.add(step.id);
    final nextStepId =
        index + 1 < orderedSteps.length ? orderedSteps[index + 1].id : null;
    nodes.add(
      GlobalStoryStepNode(
        stepId: step.id,
        exitMode: GlobalStoryStepExitMode.linear,
        links: nextStepId == null
            ? const <GlobalStoryStepLink>[]
            : <GlobalStoryStepLink>[
                GlobalStoryStepLink(toStepId: nextStepId),
              ],
      ),
    );
  }

  // Chapitre par défaut contenant toutes les steps — la structure est
  // immédiatement lisible comme un arc narratif unique.
  final defaultChapter = GlobalStoryChapter(
    id: _defaultChapterId,
    name: _defaultChapterName,
    description: '',
    stepIds: allStepIds,
    order: 0,
  );

  return GlobalStoryStudioDocument(
    globalStoryScenarioId: globalStoryScenarioId,
    entryStepId: orderedSteps.first.id,
    nodes: nodes,
    chapters: <GlobalStoryChapter>[defaultChapter],
  );
}

/// Identifiant du chapitre par défaut (quand aucun chapitre n'est défini).
const String _defaultChapterId = 'chapter_main';

/// Nom affiché du chapitre par défaut.
const String _defaultChapterName = 'Histoire principale';

/// Normalise le document macro pour éviter les incohérences structurelles.
///
/// Invariants garantis après normalisation:
/// - 1 noeud max par stepId;
/// - tous les stepId référencés existent dans le Step Studio document;
/// - entryStepId pointe vers une step existante (ou vide si aucune step);
/// - liens invalides (self-link, target inconnu, doublons) supprimés;
/// - mode linéaire/convergence borné à une destination max;
/// - fallback linéaire par ordre si aucun lien explicite;
/// - **si aucun chapitre n'existe**, un chapitre par défaut est créé;
/// - **les steps non assignées** sont ajoutées au chapitre par défaut.
GlobalStoryStudioDocument normalizeGlobalStoryStudioDocument({
  required GlobalStoryStudioDocument document,
  required StepStudioDocument stepDocument,
}) {
  final orderedSteps = stepDocument.steps.toList(growable: false)
    ..sort((a, b) => a.order.compareTo(b.order));
  final orderedStepIds = orderedSteps.map((entry) => entry.id).toList();
  final stepIdSet = orderedStepIds.toSet();

  if (orderedStepIds.isEmpty) {
    return document.copyWith(
      schemaVersion: kGlobalStoryStudioSchemaVersion,
      globalStoryScenarioId: stepDocument.globalStoryScenarioId,
      entryStepId: '',
      nodes: const <GlobalStoryStepNode>[],
      chapters: const <GlobalStoryChapter>[],
    );
  }

  final indexedNodes = <String, GlobalStoryStepNode>{};
  for (final node in document.nodes) {
    final stepId = node.stepId.trim();
    if (stepId.isEmpty || !stepIdSet.contains(stepId)) {
      continue;
    }
    // Premier noeud gagnant pour éviter les conflits de duplication.
    indexedNodes.putIfAbsent(stepId, () => node.copyWith(stepId: stepId));
  }

  final normalizedNodes = <GlobalStoryStepNode>[];
  for (var index = 0; index < orderedStepIds.length; index++) {
    final stepId = orderedStepIds[index];
    final source = indexedNodes[stepId] ??
        GlobalStoryStepNode(
          stepId: stepId,
          exitMode: GlobalStoryStepExitMode.linear,
        );
    final normalizedLinks = _normalizeNodeLinks(
      fromStepId: stepId,
      links: source.links,
      stepIdSet: stepIdSet,
      exitMode: source.exitMode,
    );
    final defaultNextId =
        index + 1 < orderedStepIds.length ? orderedStepIds[index + 1] : null;
    final withFallback = normalizedLinks.isEmpty &&
            defaultNextId != null &&
            source.exitMode == GlobalStoryStepExitMode.linear
        ? <GlobalStoryStepLink>[GlobalStoryStepLink(toStepId: defaultNextId)]
        : normalizedLinks;

    normalizedNodes.add(
      source.copyWith(
        stepId: stepId,
        links: withFallback,
      ),
    );
  }

  final entryStepId = stepIdSet.contains(document.entryStepId)
      ? document.entryStepId
      : orderedStepIds.first;

  // --- Normalisation des chapitres ---
  // Si aucun chapitre n'existe, on crée le chapitre par défaut avec toutes
  // les steps. Sinon, on nettoie les chapitres existants.
  final normalizedChapters = _normalizeChapters(
    existingChapters: document.chapters,
    allStepIds: orderedStepIds,
  );

  return document.copyWith(
    schemaVersion: kGlobalStoryStudioSchemaVersion,
    globalStoryScenarioId: stepDocument.globalStoryScenarioId,
    entryStepId: entryStepId,
    nodes: normalizedNodes,
    chapters: normalizedChapters,
  );
}

/// Normalise les chapitres pour garantir l'invariant:
/// - toutes les steps sont assignées à exactement un chapitre;
/// - si aucun chapitre n'existe, un chapitre par défaut est créé;
/// - les steps non assignées sont ajoutées au chapitre par défaut.
List<GlobalStoryChapter> _normalizeChapters({
  required List<GlobalStoryChapter> existingChapters,
  required List<String> allStepIds,
}) {
  final allStepIdSet = allStepIds.toSet();

  // Collecte les steps déjà assignées et nettoie les chapitres existants.
  final assignedStepIds = <String>{};
  final normalizedChapters = <GlobalStoryChapter>[];

  final orderedChapters = existingChapters.toList(growable: true)
    ..sort((a, b) => a.order.compareTo(b.order));

  var orderCounter = 0;
  for (final chapter in orderedChapters) {
    // Filtre les stepIds invalides ou duplicates.
    final validStepIds = <String>[];
    for (final stepId in chapter.stepIds) {
      if (allStepIdSet.contains(stepId) && !assignedStepIds.contains(stepId)) {
        validStepIds.add(stepId);
        assignedStepIds.add(stepId);
      }
    }

    normalizedChapters.add(
      chapter.copyWith(
        stepIds: validStepIds,
        order: orderCounter,
      ),
    );
    orderCounter++;
  }

  // Si aucun chapitre n'existe ou si des steps restent non assignées,
  // on utilise le chapitre par défaut.
  final unassignedSteps = allStepIds
      .where((id) => !assignedStepIds.contains(id))
      .toList(growable: false);

  // Cherche le chapitre par défaut existant ou en crée un.
  final defaultChapterIdx = normalizedChapters.indexWhere(
    (c) => c.id == _defaultChapterId,
  );
  if (defaultChapterIdx >= 0) {
    // Met à jour le chapitre par défaut avec les steps non assignées.
    final existing = normalizedChapters[defaultChapterIdx];
    normalizedChapters[defaultChapterIdx] = existing.copyWith(
      stepIds: <String>[...existing.stepIds, ...unassignedSteps],
    );
  } else if (unassignedSteps.isNotEmpty || normalizedChapters.isEmpty) {
    // Crée un chapitre par défaut.
    normalizedChapters.add(GlobalStoryChapter(
      id: _defaultChapterId,
      name: _defaultChapterName,
      description: '',
      stepIds: unassignedSteps.isEmpty ? allStepIds : unassignedSteps,
      order: orderCounter,
    ));
  }

  // Re-ordonne les chapitres.
  final finalChapters = <GlobalStoryChapter>[];
  for (var i = 0; i < normalizedChapters.length; i++) {
    finalChapters.add(normalizedChapters[i].copyWith(order: i));
  }

  return finalChapters;
}

/// Produit des diagnostics "produit" lisibles pour l'UI.
List<String> computeGlobalStoryStudioDiagnostics({
  required GlobalStoryStudioDocument document,
  required StepStudioDocument stepDocument,
  List<String> existingWarnings = const <String>[],
}) {
  final warnings = <String>[...existingWarnings];
  final orderedSteps = stepDocument.steps.toList(growable: false)
    ..sort((a, b) => a.order.compareTo(b.order));
  final stepIds = orderedSteps.map((entry) => entry.id).toSet();
  if (stepIds.isEmpty) {
    warnings.add('Aucune step disponible dans le Step Studio document.');
    return warnings;
  }

  if (!stepIds.contains(document.entryStepId)) {
    warnings.add(
      'La step de départ est invalide. Le studio utilisera la première step.',
    );
  }

  final nodeByStepId = <String, GlobalStoryStepNode>{
    for (final node in document.nodes) node.stepId: node,
  };
  for (final step in orderedSteps) {
    if (!nodeByStepId.containsKey(step.id)) {
      warnings.add(
        'Step "${step.name}" absente de la structure globale (auto-ajout conseillé).',
      );
    }
  }

  final incomingCounts = <String, int>{
    for (final step in orderedSteps) step.id: 0,
  };
  for (final node in document.nodes) {
    for (final link in node.links) {
      final target = link.toStepId.trim();
      if (!stepIds.contains(target)) {
        warnings.add(
          'Lien invalide: "${node.stepId}" pointe vers une step inconnue "$target".',
        );
        continue;
      }
      if (target == node.stepId) {
        warnings.add(
          'Boucle locale détectée sur "${node.stepId}" (lien vers elle-même).',
        );
      }
      incomingCounts[target] = (incomingCounts[target] ?? 0) + 1;
    }
    if (node.exitMode == GlobalStoryStepExitMode.branchConditional) {
      for (final link in node.links) {
        final hasConditionLabel = (link.conditionLabel ?? '').trim().isNotEmpty;
        final hasOutcome = (link.requiredOutcomeId ?? '').trim().isNotEmpty;
        if (!hasConditionLabel && !hasOutcome) {
          warnings.add(
            'Branche conditionnelle incomplète sur "${node.stepId}": ajoutez un libellé ou un outcome attendu.',
          );
          break;
        }
      }
    }
  }

  final normalizedEntry = stepIds.contains(document.entryStepId)
      ? document.entryStepId
      : orderedSteps.first.id;
  final reachable = _reachableSteps(
    entryStepId: normalizedEntry,
    nodeByStepId: nodeByStepId,
  );
  for (final step in orderedSteps) {
    if (!reachable.contains(step.id)) {
      warnings.add(
        'Step orpheline: "${step.name}" n\'est pas atteignable depuis la step de départ.',
      );
    }
  }

  for (final step in orderedSteps) {
    final node = nodeByStepId[step.id];
    final outgoingCount = node?.links.length ?? 0;
    final incoming = incomingCounts[step.id] ?? 0;
    final isTerminal = step.id == orderedSteps.last.id;
    if (!isTerminal && incoming > 0 && outgoingCount == 0) {
      warnings.add(
        'Cul-de-sac: "${step.name}" est atteinte mais ne mène à aucune suite.',
      );
    }
  }

  return warnings;
}

List<GlobalStoryStepLink> _normalizeNodeLinks({
  required String fromStepId,
  required List<GlobalStoryStepLink> links,
  required Set<String> stepIdSet,
  required GlobalStoryStepExitMode exitMode,
}) {
  final normalized = <GlobalStoryStepLink>[];
  final seen = <String>{};
  for (final link in links) {
    final target = link.toStepId.trim();
    if (target.isEmpty || !stepIdSet.contains(target)) {
      continue;
    }
    if (target == fromStepId) {
      continue;
    }
    final key =
        '$target|${link.requiredOutcomeId ?? ''}|${link.conditionLabel ?? ''}';
    if (!seen.add(key)) {
      continue;
    }
    normalized.add(
      link.copyWith(
        toStepId: target,
        conditionLabel: _trimOrNull(link.conditionLabel),
        requiredOutcomeId: _trimOrNull(link.requiredOutcomeId),
      ),
    );
  }

  if (exitMode == GlobalStoryStepExitMode.linear ||
      exitMode == GlobalStoryStepExitMode.converge) {
    return normalized.isEmpty
        ? const <GlobalStoryStepLink>[]
        : <GlobalStoryStepLink>[normalized.first];
  }
  return normalized;
}

Set<String> _reachableSteps({
  required String entryStepId,
  required Map<String, GlobalStoryStepNode> nodeByStepId,
}) {
  final visited = <String>{};
  final queue = <String>[entryStepId];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (!visited.add(current)) {
      continue;
    }
    final node = nodeByStepId[current];
    if (node == null) {
      continue;
    }
    for (final link in node.links) {
      final target = link.toStepId.trim();
      if (target.isNotEmpty && !visited.contains(target)) {
        queue.add(target);
      }
    }
  }
  return visited;
}

GlobalStoryStepExitMode _parseGlobalStoryStepExitMode(
  String? raw, {
  required GlobalStoryStepExitMode fallback,
}) {
  for (final mode in GlobalStoryStepExitMode.values) {
    if (mode.name == raw) {
      return mode;
    }
  }
  return fallback;
}

String? _trimOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

String _trimOrEmpty(Object? value) => _trimOrNull(value) ?? '';

const Object _unset = Object();
