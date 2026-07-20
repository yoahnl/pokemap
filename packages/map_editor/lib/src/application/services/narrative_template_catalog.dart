import 'package:map_core/map_core.dart';

/// Classic no-code compositions offered by the Narrative Studio.
///
/// A template always owns narrative orchestration only. Its physical entity,
/// object, zone or warp remains owned by the Map Editor and must already exist.
enum NarrativeTemplateKind {
  simpleNpc,
  conditionalNpc,
  itemBall,
  hiddenItem,
  doorWarp,
  trainer,
  shop,
  nurse,
  starter,
  badgeReward,
}

enum NarrativeTemplatePhysicalSourceKind { entity, object, zone, warp }

final class NarrativeTemplateDefinition {
  NarrativeTemplateDefinition({
    required this.kind,
    required this.label,
    required this.command,
    required this.physicalSourceKind,
    Map<String, String> additionalRequiredParameters = const <String, String>{},
  }) : additionalRequiredParameters =
            Map<String, String>.unmodifiable(additionalRequiredParameters);

  final NarrativeTemplateKind kind;
  final String label;
  final NarrativeCommandDescriptor command;
  final NarrativeTemplatePhysicalSourceKind? physicalSourceKind;

  /// Template-only inputs which do not belong to the command payload itself.
  /// For example, a conditional NPC needs a Fact to guard its Event.
  final Map<String, String> additionalRequiredParameters;

  bool get isPublishable => command.isPublishable;
}

final class NarrativeTemplateCatalog {
  NarrativeTemplateCatalog._(this.templates);

  factory NarrativeTemplateCatalog.canonical({
    NarrativeCommandCatalog? commandCatalog,
  }) {
    final commands = commandCatalog ?? NarrativeCommandCatalog.canonical();
    NarrativeCommandDescriptor command(String id) {
      final descriptor = commands.byId(id);
      if (descriptor == null) {
        throw StateError('Missing Narrative command descriptor: $id');
      }
      return descriptor;
    }

    return NarrativeTemplateCatalog._(
      List<NarrativeTemplateDefinition>.unmodifiable([
        NarrativeTemplateDefinition(
          kind: NarrativeTemplateKind.simpleNpc,
          label: 'PNJ simple',
          command: command(NarrativeCommandIds.dialogue),
          physicalSourceKind: NarrativeTemplatePhysicalSourceKind.entity,
        ),
        NarrativeTemplateDefinition(
          kind: NarrativeTemplateKind.conditionalNpc,
          label: 'PNJ conditionnel',
          command: command(NarrativeCommandIds.dialogue),
          physicalSourceKind: NarrativeTemplatePhysicalSourceKind.entity,
          additionalRequiredParameters: const {
            'factId': 'Fact de condition',
            'expectedValue': 'Valeur attendue',
          },
        ),
        NarrativeTemplateDefinition(
          kind: NarrativeTemplateKind.itemBall,
          label: 'Item ball',
          command: command(NarrativeCommandIds.giveItem),
          physicalSourceKind: NarrativeTemplatePhysicalSourceKind.object,
        ),
        NarrativeTemplateDefinition(
          kind: NarrativeTemplateKind.hiddenItem,
          label: 'Objet caché',
          command: command(NarrativeCommandIds.giveItem),
          physicalSourceKind: NarrativeTemplatePhysicalSourceKind.zone,
        ),
        NarrativeTemplateDefinition(
          kind: NarrativeTemplateKind.doorWarp,
          label: 'Porte / Warp',
          command: command(NarrativeCommandIds.warp),
          physicalSourceKind: NarrativeTemplatePhysicalSourceKind.warp,
        ),
        NarrativeTemplateDefinition(
          kind: NarrativeTemplateKind.trainer,
          label: 'Dresseur',
          command: command(NarrativeCommandIds.trainerBattle),
          physicalSourceKind: NarrativeTemplatePhysicalSourceKind.entity,
        ),
        NarrativeTemplateDefinition(
          kind: NarrativeTemplateKind.shop,
          label: 'Boutique',
          command: command(NarrativeCommandIds.openShop),
          physicalSourceKind: NarrativeTemplatePhysicalSourceKind.entity,
        ),
        NarrativeTemplateDefinition(
          kind: NarrativeTemplateKind.nurse,
          label: 'Infirmière',
          command: command(NarrativeCommandIds.healParty),
          physicalSourceKind: NarrativeTemplatePhysicalSourceKind.entity,
        ),
        NarrativeTemplateDefinition(
          kind: NarrativeTemplateKind.starter,
          label: 'Choix du starter',
          command: command(NarrativeCommandIds.giveConfiguredStarter),
          physicalSourceKind: NarrativeTemplatePhysicalSourceKind.object,
        ),
        NarrativeTemplateDefinition(
          kind: NarrativeTemplateKind.badgeReward,
          label: 'Récompense de badge',
          command: command(NarrativeCommandIds.awardBadge),
          physicalSourceKind: null,
        ),
      ]),
    );
  }

  final List<NarrativeTemplateDefinition> templates;

  NarrativeTemplateDefinition byKind(NarrativeTemplateKind kind) =>
      templates.firstWhere((template) => template.kind == kind);
}

final class NarrativeTemplatePhysicalSource {
  const NarrativeTemplatePhysicalSource({
    required this.kind,
    required this.mapId,
    required this.sourceId,
    required this.exists,
  });

  final NarrativeTemplatePhysicalSourceKind kind;
  final String mapId;
  final String sourceId;
  final bool exists;
}

final class NarrativeTemplateRequest {
  NarrativeTemplateRequest({
    required this.kind,
    required this.eventId,
    required this.sceneId,
    required this.name,
    required this.source,
    required this.physicalSource,
    Map<String, String> parameters = const <String, String>{},
  }) : parameters = Map<String, String>.unmodifiable(parameters);

  final NarrativeTemplateKind kind;
  final String eventId;
  final String sceneId;
  final String name;
  final NarrativeEventSourceRef source;
  final NarrativeTemplatePhysicalSource? physicalSource;
  final Map<String, String> parameters;
}

final class NarrativeTemplatePreview {
  NarrativeTemplatePreview({
    required this.request,
    required this.template,
    required this.before,
    required this.after,
    required this.event,
    required this.scene,
    required List<String> diagnostics,
    required this.requiresMapEditor,
  }) : diagnostics = List<String>.unmodifiable(diagnostics);

  final NarrativeTemplateRequest request;
  final NarrativeTemplateDefinition template;
  final ProjectManifest before;
  final ProjectManifest? after;
  final NarrativeEventDefinition? event;
  final SceneAsset? scene;
  final List<String> diagnostics;
  final bool requiresMapEditor;

  bool get canApply => after != null && diagnostics.isEmpty;
}

/// Produces a side-effect-free Event + Scene preview.
///
/// This function intentionally cannot create a map source. A blocked preview
/// returns [NarrativeTemplatePreview.requiresMapEditor] so the UI can navigate
/// to the owning workspace and resume with the same draft afterwards.
NarrativeTemplatePreview previewNarrativeTemplate({
  required ProjectManifest project,
  required NarrativeTemplateRequest request,
  NarrativeTemplateCatalog? templateCatalog,
}) {
  final catalog = templateCatalog ?? NarrativeTemplateCatalog.canonical();
  final template = catalog.byKind(request.kind);
  final diagnostics = <String>[];
  var requiresMapEditor = false;

  if (request.name.trim().isEmpty) {
    diagnostics.add('Le nom de la composition est obligatoire.');
  }
  if (!template.isPublishable) {
    diagnostics.add(
      template.command.capabilities.reason ??
          'La commande ${template.command.id} n’est pas publiable.',
    );
  }
  if (project.scenes.any((scene) => scene.id == request.sceneId)) {
    diagnostics.add('Une Scene utilise déjà l’ID ${request.sceneId}.');
  }
  if (project.eventRegistry?.records
          .any((record) => record.id == request.eventId) ==
      true) {
    diagnostics.add('Un Event utilise déjà l’ID ${request.eventId}.');
  }

  final physicalDiagnostic = _diagnosePhysicalSource(template, request);
  if (physicalDiagnostic != null) {
    diagnostics.add(physicalDiagnostic);
    requiresMapEditor = true;
  }

  final requiredParameters = <String, String>{
    for (final parameter in template.command.parameters)
      if (parameter.required) parameter.id: parameter.label,
    ...template.additionalRequiredParameters,
  };
  final missingParameters = <String>[
    for (final entry in requiredParameters.entries)
      if (request.parameters[entry.key]?.trim().isEmpty ?? true) entry.value,
  ];
  if (missingParameters.isNotEmpty) {
    diagnostics.add('Paramètres manquants : ${missingParameters.join(', ')}.');
  }
  diagnostics.addAll(
    _diagnoseParameterValues(template.command, request.parameters),
  );
  if (request.kind == NarrativeTemplateKind.conditionalNpc &&
      request.parameters['expectedValue'] != 'true' &&
      request.parameters['expectedValue'] != 'false') {
    diagnostics.add('La valeur attendue doit valoir vrai ou faux.');
  }

  if (diagnostics.isNotEmpty) {
    return NarrativeTemplatePreview(
      request: request,
      template: template,
      before: project,
      after: null,
      event: null,
      scene: null,
      diagnostics: diagnostics,
      requiresMapEditor: requiresMapEditor,
    );
  }

  final payload = buildScenePayloadForNarrativeCommand(
    commandId: template.command.id,
    parameters: request.parameters,
  );
  final scene = _buildTemplateScene(request, payload);
  final registry = project.eventRegistry;
  final event = NarrativeEventDefinition(
    id: request.eventId,
    name: request.name,
    source: request.source,
    conditions: request.kind == NarrativeTemplateKind.conditionalNpc
        ? <NarrativeEventCondition>[
            NarrativeEventCondition.fact(
              request.parameters['factId']!,
              request.parameters['expectedValue'] == 'true',
            ),
          ]
        : const <NarrativeEventCondition>[],
    sceneId: scene.id,
    reusePolicy: _reusePolicy(request.kind),
    priority: 0,
    order: registry?.records.length ?? 0,
  );
  final nextRegistry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: registry?.mode ?? EventSystemMode.dualRead,
    records: <NarrativeEventRecord>[
      ...?registry?.records,
      NarrativeEventRecord.configuredStructurallyUnchecked(
        event,
        enabled: true,
      ),
    ],
    legacyClaims: registry?.legacyClaims ?? const <LegacySourceClaim>[],
  );
  final after = project.copyWith(
    scenes: <SceneAsset>[...project.scenes, scene],
    eventRegistry: nextRegistry,
  );
  return NarrativeTemplatePreview(
    request: request,
    template: template,
    before: project,
    after: after,
    event: event,
    scene: scene,
    diagnostics: const <String>[],
    requiresMapEditor: false,
  );
}

String? _diagnosePhysicalSource(
  NarrativeTemplateDefinition template,
  NarrativeTemplateRequest request,
) {
  final expectedKind = template.physicalSourceKind;
  if (expectedKind == null) return null;
  final physical = request.physicalSource;
  if (physical == null || !physical.exists || physical.kind != expectedKind) {
    return 'La source physique ${expectedKind.name} doit exister dans le Map Editor.';
  }

  final sourceJson = request.source.toJson();
  final sourceMapId = sourceJson['mapId'];
  final sourceId = switch (physical.kind) {
    NarrativeTemplatePhysicalSourceKind.entity ||
    NarrativeTemplatePhysicalSourceKind.object =>
      sourceJson['entityId'],
    NarrativeTemplatePhysicalSourceKind.zone ||
    NarrativeTemplatePhysicalSourceKind.warp =>
      sourceJson['triggerId'],
  };
  if (sourceMapId != physical.mapId || sourceId != physical.sourceId) {
    return 'La source physique ne correspond pas à la source de l’Event ; '
        'sélectionnez-la de nouveau dans le Map Editor.';
  }
  return null;
}

List<String> _diagnoseParameterValues(
  NarrativeCommandDescriptor command,
  Map<String, String> parameters,
) {
  final diagnostics = <String>[];
  for (final parameter in command.parameters) {
    final value = parameters[parameter.id]?.trim();
    if (value == null || value.isEmpty) continue;
    switch (parameter.kind) {
      case NarrativeCommandParameterKind.integer:
        final parsed = int.tryParse(value);
        if (parsed == null || parsed <= 0) {
          diagnostics.add('${parameter.label} doit être un entier positif.');
        }
      case NarrativeCommandParameterKind.boolean:
        if (value != 'true' && value != 'false') {
          diagnostics.add('${parameter.label} doit valoir vrai ou faux.');
        }
      default:
        break;
    }
  }
  return diagnostics;
}

NarrativeEventReusePolicy _reusePolicy(NarrativeTemplateKind kind) =>
    switch (kind) {
      NarrativeTemplateKind.simpleNpc ||
      NarrativeTemplateKind.conditionalNpc ||
      NarrativeTemplateKind.doorWarp ||
      NarrativeTemplateKind.shop ||
      NarrativeTemplateKind.nurse =>
        NarrativeEventReusePolicy.reusable,
      NarrativeTemplateKind.itemBall ||
      NarrativeTemplateKind.hiddenItem ||
      NarrativeTemplateKind.trainer ||
      NarrativeTemplateKind.starter ||
      NarrativeTemplateKind.badgeReward =>
        NarrativeEventReusePolicy.oneShot,
    };

/// Converts a publishable command form into its one canonical Scene wire.
SceneNodePayload buildScenePayloadForNarrativeCommand({
  required String commandId,
  required Map<String, String> parameters,
}) {
  int integer(String id, {int fallback = 1}) =>
      int.tryParse(parameters[id] ?? '') ?? fallback;
  return switch (commandId) {
    NarrativeCommandIds.setFact => SceneActionPayload.consequence(
        SceneConsequence.setFact(
          factId: parameters['factId']!,
          value: parameters['value'] == 'true',
        ),
      ),
    NarrativeCommandIds.markEventConsumed => SceneActionPayload.consequence(
        SceneConsequence.markEventConsumed(
          mapId: parameters['mapId']!,
          eventId: parameters['eventId']!,
        ),
      ),
    NarrativeCommandIds.completeStoryStep => SceneActionPayload.consequence(
        SceneConsequence.completeStoryStep(stepId: parameters['stepId']!),
      ),
    NarrativeCommandIds.giveItem => SceneActionPayload.consequence(
        SceneConsequence.giveItem(
          itemId: parameters['itemId']!,
          quantity: integer('quantity'),
        ),
      ),
    NarrativeCommandIds.takeItem => SceneActionPayload.consequence(
        SceneConsequence.takeItem(
          itemId: parameters['itemId']!,
          quantity: integer('quantity'),
        ),
      ),
    NarrativeCommandIds.giveMoney => SceneActionPayload.consequence(
        SceneConsequence.giveMoney(amount: integer('amount')),
      ),
    NarrativeCommandIds.givePokemon => SceneActionPayload.consequence(
        SceneConsequence.givePokemon(
          speciesId: parameters['speciesId']!,
          level: integer('level'),
          currentHp: integer('currentHp', fallback: integer('level')),
          natureId: parameters['natureId'] ?? 'hardy',
          abilityId: parameters['abilityId'] ?? 'unknown',
        ),
      ),
    NarrativeCommandIds.giveConfiguredStarter => SceneActionPayload.consequence(
        SceneConsequence.giveConfiguredStarter(
          starterOptionId: parameters['starterOptionId']!,
        ),
      ),
    NarrativeCommandIds.warp => SceneActionPayload.interactive(
        SceneInteractiveCommand.warp(
          destinationMapId: parameters['destinationMapId']!,
          warpId: parameters['warpId']!,
        ),
      ),
    NarrativeCommandIds.openShop => SceneActionPayload.interactive(
        SceneInteractiveCommand.openShop(shopId: parameters['shopId']!),
      ),
    NarrativeCommandIds.openPc => SceneActionPayload.interactive(
        switch (parameters['storageId']) {
          final storageId? =>
            SceneInteractiveCommand.openPc(storageId: storageId),
          null => SceneInteractiveCommand.openPc(),
        },
      ),
    NarrativeCommandIds.dialogue => SceneYarnDialoguePayload(
        dialogueId: parameters['dialogueId']!,
      ),
    NarrativeCommandIds.trainerBattle => SceneBattlePayload(
        battleKind: 'trainer',
        trainerId: parameters['trainerId']!,
      ),
    NarrativeCommandIds.staticEncounter => SceneBattlePayload(
        battleKind: 'static',
        battleTemplateId: parameters['speciesId']!,
      ),
    NarrativeCommandIds.cinematic => SceneCinematicPayload(
        cinematicId: parameters['cinematicId']!,
      ),
    _ => throw ArgumentError.value(
        commandId,
        'commandId',
        'An unsupported Narrative command cannot produce a Scene payload.',
      ),
  };
}

SceneAsset _buildTemplateScene(
  NarrativeTemplateRequest request,
  SceneNodePayload payload,
) {
  final startId = '${request.sceneId}.start';
  final contentId = '${request.sceneId}.content';
  final endId = '${request.sceneId}.end';
  final content = SceneNode(
    id: contentId,
    kind: payload.kind,
    title: request.name,
    payload: payload,
  );
  final contentEdges = switch (payload) {
    SceneBattlePayload() => <SceneEdge>[
        SceneEdge(
          id: '${request.sceneId}.content-victory',
          fromNodeId: contentId,
          fromPortId: 'victory',
          toNodeId: endId,
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: '${request.sceneId}.content-defeat',
          fromNodeId: contentId,
          fromPortId: 'defeat',
          toNodeId: endId,
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    SceneCinematicPayload() => <SceneEdge>[
        SceneEdge(
          id: '${request.sceneId}.content-end',
          fromNodeId: contentId,
          fromPortId: 'completed',
          toNodeId: endId,
          kind: SceneEdgeKind.cinematicCompleted,
        ),
      ],
    SceneActionPayload() => <SceneEdge>[
        SceneEdge(
          id: '${request.sceneId}.content-end',
          fromNodeId: contentId,
          fromPortId: 'completed',
          toNodeId: endId,
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    SceneYarnDialoguePayload() => <SceneEdge>[
        SceneEdge(
          id: '${request.sceneId}.content-end',
          fromNodeId: contentId,
          fromPortId: 'completed',
          toNodeId: endId,
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    _ => throw StateError(
        'Template command produced an unsupported node kind: ${payload.kind}',
      ),
  };
  return SceneAsset(
    id: request.sceneId,
    name: request.name,
    graph: SceneGraph(
      startNodeId: startId,
      nodes: <SceneNode>[
        SceneNode(id: startId, kind: SceneNodeKind.start),
        content,
        SceneNode(id: endId, kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: '${request.sceneId}.start-content',
          fromNodeId: startId,
          fromPortId: 'completed',
          toNodeId: contentId,
          kind: SceneEdgeKind.defaultFlow,
        ),
        ...contentEdges,
      ],
    ),
  );
}

enum NarrativeTemplateTransactionStatus { prepared, projectWritten, committed }

/// Durable write-ahead record. Implementations persist this JSON separately
/// from project.json so an interrupted multi-section mutation can be recovered.
final class NarrativeTemplateTransactionRecord {
  const NarrativeTemplateTransactionRecord({
    required this.transactionId,
    required this.status,
    required this.before,
    required this.after,
  });

  factory NarrativeTemplateTransactionRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    final statusName = json['status'];
    final status = NarrativeTemplateTransactionStatus.values
        .where((value) => value.name == statusName)
        .firstOrNull;
    if (status == null) {
      throw const FormatException(
        'Unknown Narrative template journal status.',
      );
    }
    return NarrativeTemplateTransactionRecord(
      transactionId: json['transactionId'] as String,
      status: status,
      before: ProjectManifest.fromJson(
        Map<String, dynamic>.from(json['before'] as Map),
      ),
      after: ProjectManifest.fromJson(
        Map<String, dynamic>.from(json['after'] as Map),
      ),
    );
  }

  final String transactionId;
  final NarrativeTemplateTransactionStatus status;
  final ProjectManifest before;
  final ProjectManifest after;

  NarrativeTemplateTransactionRecord copyWith({
    NarrativeTemplateTransactionStatus? status,
  }) =>
      NarrativeTemplateTransactionRecord(
        transactionId: transactionId,
        status: status ?? this.status,
        before: before,
        after: after,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'transactionId': transactionId,
        'status': status.name,
        'before': before.toJson(),
        'after': after.toJson(),
      };
}

abstract interface class NarrativeTemplateTransactionGateway {
  Future<ProjectManifest> readProject();
  Future<void> writeProject(ProjectManifest project);
  Future<NarrativeTemplateTransactionRecord?> readJournal();
  Future<void> writeJournal(NarrativeTemplateTransactionRecord record);
  Future<void> clearJournal();
}

final class NarrativeTemplateTransactionCoordinator {
  const NarrativeTemplateTransactionCoordinator(this.gateway);

  final NarrativeTemplateTransactionGateway gateway;

  Future<void> apply({
    required String transactionId,
    required NarrativeTemplatePreview preview,
  }) async {
    if (!preview.canApply) {
      throw StateError('A blocked template preview cannot be applied.');
    }
    final current = await gateway.readProject();
    if (current != preview.before) {
      throw StateError('Project changed after the template preview.');
    }
    var journal = NarrativeTemplateTransactionRecord(
      transactionId: transactionId,
      status: NarrativeTemplateTransactionStatus.prepared,
      before: preview.before,
      after: preview.after!,
    );
    await gateway.writeJournal(journal);
    await gateway.writeProject(preview.after!);
    journal = journal.copyWith(
      status: NarrativeTemplateTransactionStatus.projectWritten,
    );
    await gateway.writeJournal(journal);
    journal = journal.copyWith(
      status: NarrativeTemplateTransactionStatus.committed,
    );
    await gateway.writeJournal(journal);
    await gateway.clearJournal();
  }

  /// Resolves an interrupted write without guessing over unrelated changes.
  /// Uncommitted mutations roll back; a committed mutation rolls forward.
  Future<bool> recover() async {
    final journal = await gateway.readJournal();
    if (journal == null) return false;
    final current = await gateway.readProject();
    final currentIsBefore = current == journal.before;
    final currentIsAfter = current == journal.after;
    if (!currentIsBefore && !currentIsAfter) {
      throw StateError(
        'Template recovery refused because project.json changed independently.',
      );
    }
    if (journal.status == NarrativeTemplateTransactionStatus.committed) {
      if (!currentIsAfter) await gateway.writeProject(journal.after);
    } else if (!currentIsBefore) {
      await gateway.writeProject(journal.before);
    }
    await gateway.clearJournal();
    return true;
  }

  Future<void> undo(NarrativeTemplatePreview preview) async {
    final current = await gateway.readProject();
    if (current != preview.after) {
      throw StateError('Template undo refused because the project changed.');
    }
    await gateway.writeProject(preview.before);
  }
}
