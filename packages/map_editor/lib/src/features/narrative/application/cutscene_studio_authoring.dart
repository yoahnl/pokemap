import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

/// Schéma d'authoring porté par le Cutscene Studio v1.
///
/// Ce marqueur est stocké dans `ScenarioAsset.metadata` pour que:
/// - l'éditeur sache qu'un scénario est compatible avec cette UX guidée;
/// - les migrations futures puissent être ciblées proprement;
/// - on reste honnête sur le niveau de support outillé.
const String kCutsceneStudioSchemaVersion = 'cutscene_studio_v1';

/// Clé metadata où l'on stocke la version du schéma d'authoring cutscene.
const String kCutsceneStudioSchemaMetadataKey = 'authoring.cutsceneSchema';

/// Action kinds runtime (bridge scénario MVP) supportées par le studio v1.
///
/// NOTE PRODUIT:
/// Ces constantes restent côté authoring pour éviter les chaînes magiques
/// dans l'UI; elles reflètent le contrat runtime existant.
const String kCutsceneStudioActionRunScript = 'runScript';
const String kCutsceneStudioActionOpenDialogue = 'openDialogue';
const String kCutsceneStudioActionSetFlag = 'setFlag';
const String kCutsceneStudioActionClearFlag = 'clearFlag';
const String kCutsceneStudioActionEmitOutcome = 'emitOutcome';

/// Source hooks monde supportés par le studio v1.
const String kCutsceneStudioSourceMapEnter = 'sourceMapEnter';
const String kCutsceneStudioSourceTriggerEnter = 'sourceTriggerEnter';
const String kCutsceneStudioSourceEntityInteract = 'sourceEntityInteract';

/// Type de déclenchement "humain" présenté dans le studio.
enum CutsceneStudioSourceKind {
  mapEnter,
  triggerEnter,
  entityInteract,
}

String cutsceneStudioSourceKindLabel(CutsceneStudioSourceKind kind) {
  return switch (kind) {
    CutsceneStudioSourceKind.mapEnter => 'Entrée sur une map',
    CutsceneStudioSourceKind.triggerEnter => 'Entrée dans un trigger',
    CutsceneStudioSourceKind.entityInteract => 'Interaction avec un PNJ',
  };
}

/// Source du flow cutscene (hook monde).
///
/// Pourquoi c'est séparé des blocs:
/// - le hook monde répond au "quand démarre la scène ?";
/// - les blocs répondent au "que fait la scène ensuite ?".
@immutable
class CutsceneStudioSourceConfig {
  const CutsceneStudioSourceConfig({
    required this.kind,
    this.mapId,
    this.triggerId,
    this.entityId,
  });

  final CutsceneStudioSourceKind kind;
  final String? mapId;
  final String? triggerId;
  final String? entityId;

  CutsceneStudioSourceConfig copyWith({
    CutsceneStudioSourceKind? kind,
    Object? mapId = _unset,
    Object? triggerId = _unset,
    Object? entityId = _unset,
  }) {
    return CutsceneStudioSourceConfig(
      kind: kind ?? this.kind,
      mapId: identical(mapId, _unset) ? this.mapId : mapId as String?,
      triggerId:
          identical(triggerId, _unset) ? this.triggerId : triggerId as String?,
      entityId:
          identical(entityId, _unset) ? this.entityId : entityId as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CutsceneStudioSourceConfig &&
        other.kind == kind &&
        other.mapId == mapId &&
        other.triggerId == triggerId &&
        other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(kind, mapId, triggerId, entityId);
}

/// Bloc d'exécution affiché dans le Cutscene Studio.
///
/// Le v1 reste volontairement petit:
/// - `dialogue`
/// - `runScript`
/// - `setFlag` / `clearFlag`
/// - `emitOutcome`
///
/// Cette contrainte permet de livrer une UX guidée stable sans mentir sur
/// le support runtime actuellement branché.
enum CutsceneStudioBlockKind {
  dialogue,
  runScript,
  setFlag,
  clearFlag,
  emitOutcome,
}

String cutsceneStudioBlockKindLabel(CutsceneStudioBlockKind kind) {
  return switch (kind) {
    CutsceneStudioBlockKind.dialogue => 'Dialogue',
    CutsceneStudioBlockKind.runScript => 'Exécuter un script',
    CutsceneStudioBlockKind.setFlag => 'Activer un flag',
    CutsceneStudioBlockKind.clearFlag => 'Désactiver un flag',
    CutsceneStudioBlockKind.emitOutcome => 'Émettre un outcome',
  };
}

@immutable
class CutsceneStudioBlock {
  const CutsceneStudioBlock({
    required this.id,
    required this.kind,
    this.dialogueId,
    this.scriptId,
    this.flagName,
    this.outcomeId,
  });

  final String id;
  final CutsceneStudioBlockKind kind;
  final String? dialogueId;
  final String? scriptId;
  final String? flagName;
  final String? outcomeId;

  CutsceneStudioBlock copyWith({
    String? id,
    CutsceneStudioBlockKind? kind,
    Object? dialogueId = _unset,
    Object? scriptId = _unset,
    Object? flagName = _unset,
    Object? outcomeId = _unset,
  }) {
    return CutsceneStudioBlock(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      dialogueId: identical(dialogueId, _unset)
          ? this.dialogueId
          : dialogueId as String?,
      scriptId:
          identical(scriptId, _unset) ? this.scriptId : scriptId as String?,
      flagName:
          identical(flagName, _unset) ? this.flagName : flagName as String?,
      outcomeId:
          identical(outcomeId, _unset) ? this.outcomeId : outcomeId as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CutsceneStudioBlock &&
        other.id == id &&
        other.kind == kind &&
        other.dialogueId == dialogueId &&
        other.scriptId == scriptId &&
        other.flagName == flagName &&
        other.outcomeId == outcomeId;
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, dialogueId, scriptId, flagName, outcomeId);
}

/// Document d'authoring manipulé par le studio (surface centrale).
///
/// Ce modèle n'est pas le runtime: c'est une représentation UX-friendly
/// convertie ensuite vers `ScenarioAsset`.
@immutable
class CutsceneStudioDocument {
  const CutsceneStudioDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.source,
    required this.blocks,
  });

  final String id;
  final String name;
  final String description;
  final CutsceneStudioSourceConfig source;
  final List<CutsceneStudioBlock> blocks;

  CutsceneStudioDocument copyWith({
    String? id,
    String? name,
    String? description,
    CutsceneStudioSourceConfig? source,
    List<CutsceneStudioBlock>? blocks,
  }) {
    return CutsceneStudioDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      source: source ?? this.source,
      blocks: blocks ?? this.blocks,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CutsceneStudioDocument) return false;
    if (other.id != id ||
        other.name != name ||
        other.description != description ||
        other.source != source ||
        other.blocks.length != blocks.length) {
      return false;
    }
    for (var i = 0; i < blocks.length; i++) {
      if (other.blocks[i] != blocks[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        source,
        Object.hashAll(blocks),
      );
}

/// Résultat de parsing d'un scénario existant vers le format studio v1.
///
/// `editable == false` signifie:
/// - le scénario existe et reste valide;
/// - MAIS sa structure sort du périmètre guidé du studio v1 (ex: branches).
@immutable
class CutsceneStudioParseResult {
  const CutsceneStudioParseResult({
    required this.document,
    required this.editable,
    required this.warnings,
  });

  final CutsceneStudioDocument document;
  final bool editable;
  final List<String> warnings;
}

/// Templates de création rapide pour démarrer une scène sans écran vide.
enum CutsceneStudioTemplateKind {
  npcDialogue,
  mapEnterDialogue,
  npcScript,
}

String cutsceneStudioTemplateLabel(CutsceneStudioTemplateKind kind) {
  return switch (kind) {
    CutsceneStudioTemplateKind.npcDialogue =>
      'Dialogue simple (interaction PNJ)',
    CutsceneStudioTemplateKind.mapEnterDialogue => 'Entrée map -> dialogue',
    CutsceneStudioTemplateKind.npcScript => 'Interaction PNJ -> script',
  };
}

CutsceneStudioDocument createCutsceneStudioTemplateDocument({
  required CutsceneStudioTemplateKind template,
  required String id,
  required String name,
  String? description,
  String? mapId,
  String? entityId,
  String? dialogueId,
  String? scriptId,
}) {
  final source = switch (template) {
    CutsceneStudioTemplateKind.npcDialogue ||
    CutsceneStudioTemplateKind.npcScript =>
      CutsceneStudioSourceConfig(
        kind: CutsceneStudioSourceKind.entityInteract,
        mapId: mapId,
        entityId: entityId,
      ),
    CutsceneStudioTemplateKind.mapEnterDialogue => CutsceneStudioSourceConfig(
        kind: CutsceneStudioSourceKind.mapEnter,
        mapId: mapId,
      ),
  };

  final blocks = switch (template) {
    CutsceneStudioTemplateKind.npcDialogue ||
    CutsceneStudioTemplateKind.mapEnterDialogue =>
      <CutsceneStudioBlock>[
        CutsceneStudioBlock(
          id: 'block_dialogue_1',
          kind: CutsceneStudioBlockKind.dialogue,
          dialogueId: dialogueId,
        ),
      ],
    CutsceneStudioTemplateKind.npcScript => <CutsceneStudioBlock>[
        CutsceneStudioBlock(
          id: 'block_script_1',
          kind: CutsceneStudioBlockKind.runScript,
          scriptId: scriptId,
        ),
      ],
  };

  return CutsceneStudioDocument(
    id: id,
    name: name,
    description: description?.trim() ?? '',
    source: source,
    blocks: blocks,
  );
}

/// Convertit un `ScenarioAsset` existant vers une vue "blocs guidés".
///
/// Le parseur v1 accepte UNIQUEMENT un flow linéaire:
/// `start -> source -> action* -> end`.
///
/// Si un scénario contient des choix/conditions/branches, il reste valide
/// côté projet, mais devient `editable = false` dans ce studio v1.
CutsceneStudioParseResult parseScenarioToCutsceneStudioDocument(
  ScenarioAsset scenario,
) {
  final warnings = <String>[];
  final nodesById = <String, ScenarioNode>{
    for (final node in scenario.nodes) node.id: node,
  };
  final edgesByFrom = <String, List<ScenarioEdge>>{};
  for (final edge in scenario.edges) {
    edgesByFrom.putIfAbsent(edge.fromNodeId, () => <ScenarioEdge>[]).add(edge);
  }
  for (final list in edgesByFrom.values) {
    list.sort((a, b) => a.order.compareTo(b.order));
  }

  if (scenario.scope != ScenarioScope.localEventFlow) {
    warnings.add(
      'Le studio cutscene v1 supporte uniquement les scénarios localEventFlow.',
    );
  }

  final startNode = nodesById[scenario.entryNodeId];
  if (startNode == null || startNode.type != ScenarioNodeType.start) {
    warnings.add(
      'entryNodeId doit pointer vers un node Start pour le mode guidé v1.',
    );
  }

  final sourceNode = startNode == null
      ? null
      : _resolveSingleNextNode(
          fromNode: startNode,
          nodesById: nodesById,
          edgesByFrom: edgesByFrom,
          warnings: warnings,
          contextLabel: 'Start',
        );

  final parsedSource = sourceNode == null
      ? null
      : _parseSourceNode(
          sourceNode,
          warnings: warnings,
        );

  final blocks = <CutsceneStudioBlock>[];
  if (sourceNode != null && parsedSource != null) {
    var cursor = _resolveSingleNextNode(
      fromNode: sourceNode,
      nodesById: nodesById,
      edgesByFrom: edgesByFrom,
      warnings: warnings,
      contextLabel: 'Source',
    );
    final visited = <String>{startNode!.id, sourceNode.id};

    while (cursor != null) {
      // Protection anti-boucle: le studio v1 est linéaire.
      if (!visited.add(cursor.id)) {
        warnings.add('Cycle détecté autour du node "${cursor.id}".');
        break;
      }
      if (cursor.type == ScenarioNodeType.end) {
        final outgoing = edgesByFrom[cursor.id] ?? const <ScenarioEdge>[];
        if (outgoing.isNotEmpty) {
          warnings.add(
            'Un node End ne doit pas avoir de sortie dans le mode v1.',
          );
        }
        break;
      }
      final parsed = _parseBlockNode(cursor, warnings: warnings);
      if (parsed == null) {
        break;
      }
      blocks.add(parsed);
      cursor = _resolveSingleNextNode(
        fromNode: cursor,
        nodesById: nodesById,
        edgesByFrom: edgesByFrom,
        warnings: warnings,
        contextLabel: 'Bloc ${cursor.id}',
      );
    }
  }

  final source = parsedSource ??
      const CutsceneStudioSourceConfig(
        kind: CutsceneStudioSourceKind.entityInteract,
      );
  final document = CutsceneStudioDocument(
    id: scenario.id,
    name: scenario.name,
    description: scenario.description,
    source: source,
    blocks: blocks,
  );
  return CutsceneStudioParseResult(
    document: document,
    editable: warnings.isEmpty,
    warnings: warnings,
  );
}

/// Compile la représentation "blocs" vers le format canonique `ScenarioAsset`.
///
/// Contrat du compilateur v1:
/// - produit un graphe linéaire deterministic;
/// - conserve uniquement des action kinds supportées dans ce lot;
/// - met à jour les `declaredOutcomes` à partir des blocs `emitOutcome`.
ScenarioAsset buildScenarioFromCutsceneStudioDocument(
  CutsceneStudioDocument document, {
  ScenarioAsset? previousScenario,
}) {
  final nodes = <ScenarioNode>[];
  final edges = <ScenarioEdge>[];

  const startNodeId = 'start';
  const sourceNodeId = 'source';
  const endNodeId = 'end';

  nodes.add(
    const ScenarioNode(
      id: startNodeId,
      type: ScenarioNodeType.start,
      title: 'Start',
    ),
  );
  nodes.add(
    ScenarioNode(
      id: sourceNodeId,
      type: ScenarioNodeType.reference,
      title: 'Source',
      payload: ScenarioNodePayload(
        actionKind: _sourceActionKind(document.source.kind),
      ),
      binding: ScenarioNodeBinding(
        mapId: _trimOrNull(document.source.mapId),
        triggerId: _trimOrNull(document.source.triggerId),
        entityId: _trimOrNull(document.source.entityId),
      ),
    ),
  );

  var previousNodeId = sourceNodeId;
  var edgeIndex = 1;
  final declaredOutcomes = <String>{};

  for (var index = 0; index < document.blocks.length; index++) {
    final block = document.blocks[index];
    final nodeId = _normalizeNodeId(
      block.id,
      fallback: 'block_${index + 1}',
    );
    final node = _buildNodeForBlock(block, nodeId: nodeId);
    nodes.add(node);

    edges.add(
      ScenarioEdge(
        id: 'edge_$edgeIndex',
        fromNodeId: previousNodeId,
        toNodeId: nodeId,
        kind: ScenarioEdgeKind.next,
        order: 0,
      ),
    );
    edgeIndex++;
    previousNodeId = nodeId;

    if (block.kind == CutsceneStudioBlockKind.emitOutcome) {
      final outcome = block.outcomeId?.trim();
      if (outcome != null && outcome.isNotEmpty) {
        declaredOutcomes.add(outcome);
      }
    }
  }

  nodes.add(
    const ScenarioNode(
      id: endNodeId,
      type: ScenarioNodeType.end,
      title: 'End',
    ),
  );

  edges.insert(
    0,
    const ScenarioEdge(
      id: 'edge_start_source',
      fromNodeId: startNodeId,
      toNodeId: sourceNodeId,
      kind: ScenarioEdgeKind.next,
      order: 0,
    ),
  );
  edges.add(
    ScenarioEdge(
      id: 'edge_$edgeIndex',
      fromNodeId: previousNodeId,
      toNodeId: endNodeId,
      kind: ScenarioEdgeKind.next,
      order: 0,
    ),
  );

  final previousMetadata =
      previousScenario?.metadata ?? const <String, String>{};
  final metadata = <String, String>{
    ...previousMetadata,
    kCutsceneStudioSchemaMetadataKey: kCutsceneStudioSchemaVersion,
  };

  return ScenarioAsset(
    id: document.id.trim(),
    name: document.name.trim(),
    description: document.description.trim(),
    scope: ScenarioScope.localEventFlow,
    entryNodeId: startNodeId,
    declaredOutcomes: declaredOutcomes.toList(growable: false),
    activationCondition: previousScenario?.activationCondition,
    nodes: nodes,
    edges: edges,
    metadata: metadata,
  );
}

ScenarioNode _buildNodeForBlock(
  CutsceneStudioBlock block, {
  required String nodeId,
}) {
  switch (block.kind) {
    case CutsceneStudioBlockKind.dialogue:
      // On encode en node `dialogue` pour rester lisible et cohérent avec le
      // bridge runtime MVP qui sait ouvrir un dialogue à partir de `dialogueId`.
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.dialogue,
        title: cutsceneStudioBlockKindLabel(block.kind),
        binding: ScenarioNodeBinding(
          dialogueId: _trimOrNull(block.dialogueId),
        ),
      );
    case CutsceneStudioBlockKind.runScript:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: const ScenarioNodePayload(
          actionKind: kCutsceneStudioActionRunScript,
        ),
        binding: ScenarioNodeBinding(
          scriptId: _trimOrNull(block.scriptId),
        ),
      );
    case CutsceneStudioBlockKind.setFlag:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: const ScenarioNodePayload(
          actionKind: kCutsceneStudioActionSetFlag,
        ),
        binding: ScenarioNodeBinding(
          flagName: _trimOrNull(block.flagName),
        ),
      );
    case CutsceneStudioBlockKind.clearFlag:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: const ScenarioNodePayload(
          actionKind: kCutsceneStudioActionClearFlag,
        ),
        binding: ScenarioNodeBinding(
          flagName: _trimOrNull(block.flagName),
        ),
      );
    case CutsceneStudioBlockKind.emitOutcome:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: const ScenarioNodePayload(
          actionKind: kCutsceneStudioActionEmitOutcome,
        ),
        binding: ScenarioNodeBinding(
          outcomeId: _trimOrNull(block.outcomeId),
        ),
      );
  }
}

ScenarioNode? _resolveSingleNextNode({
  required ScenarioNode fromNode,
  required Map<String, ScenarioNode> nodesById,
  required Map<String, List<ScenarioEdge>> edgesByFrom,
  required List<String> warnings,
  required String contextLabel,
}) {
  final outgoing = edgesByFrom[fromNode.id] ?? const <ScenarioEdge>[];
  if (outgoing.isEmpty) {
    warnings.add('$contextLabel n\'a aucune sortie.');
    return null;
  }
  if (outgoing.length > 1) {
    warnings.add(
      '$contextLabel a plusieurs sorties: le mode guidé v1 ne gère pas les branches.',
    );
    return null;
  }
  final edge = outgoing.first;
  if (edge.kind != ScenarioEdgeKind.next) {
    warnings.add(
      '$contextLabel utilise "${edge.kind.name}" mais le mode v1 attend "next".',
    );
    return null;
  }
  final next = nodesById[edge.toNodeId];
  if (next == null) {
    warnings.add('$contextLabel référence un node cible introuvable.');
    return null;
  }
  return next;
}

CutsceneStudioSourceConfig? _parseSourceNode(
  ScenarioNode node, {
  required List<String> warnings,
}) {
  if (node.type != ScenarioNodeType.reference) {
    warnings.add(
      'Le node source doit être de type Reference dans le mode guidé v1.',
    );
    return null;
  }
  final actionKind = node.payload.actionKind?.trim() ?? '';
  switch (actionKind) {
    case kCutsceneStudioSourceMapEnter:
      return CutsceneStudioSourceConfig(
        kind: CutsceneStudioSourceKind.mapEnter,
        mapId: _trimOrNull(node.binding.mapId),
      );
    case kCutsceneStudioSourceTriggerEnter:
      return CutsceneStudioSourceConfig(
        kind: CutsceneStudioSourceKind.triggerEnter,
        mapId: _trimOrNull(node.binding.mapId),
        triggerId: _trimOrNull(node.binding.triggerId),
      );
    case kCutsceneStudioSourceEntityInteract:
      return CutsceneStudioSourceConfig(
        kind: CutsceneStudioSourceKind.entityInteract,
        mapId: _trimOrNull(node.binding.mapId),
        entityId: _trimOrNull(node.binding.entityId),
      );
    default:
      warnings.add(
        'Source "$actionKind" non supportée par le studio guidé v1.',
      );
      return null;
  }
}

CutsceneStudioBlock? _parseBlockNode(
  ScenarioNode node, {
  required List<String> warnings,
}) {
  if (node.type == ScenarioNodeType.dialogue) {
    return CutsceneStudioBlock(
      id: node.id,
      kind: CutsceneStudioBlockKind.dialogue,
      dialogueId: _trimOrNull(node.binding.dialogueId),
    );
  }

  if (node.type != ScenarioNodeType.action) {
    warnings.add(
      'Node "${node.id}" de type "${node.type.name}" hors périmètre du mode guidé v1.',
    );
    return null;
  }

  final actionKind = node.payload.actionKind?.trim() ?? '';
  switch (actionKind) {
    case kCutsceneStudioActionRunScript:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.runScript,
        scriptId: _trimOrNull(node.binding.scriptId),
      );
    case kCutsceneStudioActionOpenDialogue:
      // Compatibilité: certains flux historiques utilisent `action/openDialogue`
      // au lieu d'un node `dialogue`.
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.dialogue,
        dialogueId: _trimOrNull(node.binding.dialogueId),
      );
    case kCutsceneStudioActionSetFlag:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.setFlag,
        flagName: _trimOrNull(node.binding.flagName),
      );
    case kCutsceneStudioActionClearFlag:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.clearFlag,
        flagName: _trimOrNull(node.binding.flagName),
      );
    case kCutsceneStudioActionEmitOutcome:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.emitOutcome,
        outcomeId: _trimOrNull(node.binding.outcomeId),
      );
    default:
      warnings.add(
        'Action "$actionKind" non supportée par le studio guidé v1.',
      );
      return null;
  }
}

String _sourceActionKind(CutsceneStudioSourceKind kind) {
  return switch (kind) {
    CutsceneStudioSourceKind.mapEnter => kCutsceneStudioSourceMapEnter,
    CutsceneStudioSourceKind.triggerEnter => kCutsceneStudioSourceTriggerEnter,
    CutsceneStudioSourceKind.entityInteract =>
      kCutsceneStudioSourceEntityInteract,
  };
}

String? _trimOrNull(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

String _normalizeNodeId(String raw, {required String fallback}) {
  final normalized = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return normalized.isEmpty ? fallback : normalized;
}

const Object _unset = Object();
