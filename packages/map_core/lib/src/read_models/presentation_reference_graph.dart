import '../models/presentation_cinematic_asset.dart';
import '../models/project_media_catalog.dart';
import '../models/scene_asset.dart';

enum PresentationReferenceKind {
  presentationCinematic,
  scene,
  asset,
  media,
  interactionCue,
}

enum PresentationReferenceRelation {
  sceneCinematic,
  clipMedia,
  mediaSource,
  mediaPoster,
  mediaCaptions,
  mediaFallback,
}

enum PresentationReferenceResolution { resolved, missing, incompatible }

enum PresentationReferenceSeverity { error }

abstract final class PresentationReferenceDiagnosticCodes {
  static const referenceMissing = 'cinematic.presentation.reference_missing';
  static const referenceAmbiguous =
      'cinematic.presentation.reference_ambiguous';
  static const referenceCycle = 'cinematic.presentation.reference_cycle';
  static const mediaMissing = 'cinematic.presentation.media_missing';
  static const mediaSourceMissing =
      'cinematic.presentation.media_source_missing';
  static const mediaUnsupported = 'cinematic.presentation.media_unsupported';
  static const resourceInUse = 'cinematic.presentation.resource_in_use';
}

final class PresentationReferenceKey {
  const PresentationReferenceKey._(this.kind, this.id, this.parentId);

  const PresentationReferenceKey.presentationCinematic(String id)
    : this._(PresentationReferenceKind.presentationCinematic, id, null);

  const PresentationReferenceKey.scene(String id)
    : this._(PresentationReferenceKind.scene, id, null);

  const PresentationReferenceKey.asset(String id)
    : this._(PresentationReferenceKind.asset, id, null);

  const PresentationReferenceKey.media(String id)
    : this._(PresentationReferenceKind.media, id, null);

  const PresentationReferenceKey.interactionCue(
    String id, {
    required String presentationCinematicId,
  }) : this._(
         PresentationReferenceKind.interactionCue,
         id,
         presentationCinematicId,
       );

  factory PresentationReferenceKey.fromJson(Map<String, Object?> json) {
    final kind = _readEnum(
      PresentationReferenceKind.values,
      json['kind'],
      'key.kind',
    );
    final id = _readString(json['id'], 'key.id');
    final parentId = _readOptionalString(json['parentId'], 'key.parentId');
    if (kind == PresentationReferenceKind.interactionCue && parentId == null) {
      throw const FormatException(
        'key.parentId is required for an interaction cue',
      );
    }
    if (kind != PresentationReferenceKind.interactionCue && parentId != null) {
      throw const FormatException(
        'key.parentId is only supported for an interaction cue',
      );
    }
    return PresentationReferenceKey._(kind, id, parentId);
  }

  final PresentationReferenceKind kind;
  final String id;
  final String? parentId;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'id': id,
    if (parentId != null) 'parentId': parentId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationReferenceKey &&
          other.kind == kind &&
          other.id == id &&
          other.parentId == parentId;

  @override
  int get hashCode => Object.hash(kind, id, parentId);
}

final class ProjectMediaSourceAssetDefinition {
  const ProjectMediaSourceAssetDefinition({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

final class PresentationReferenceNode {
  PresentationReferenceNode({
    required this.key,
    required String label,
    required this.defined,
    this.mediaType,
  }) : label = _requiredString(label, 'node.label') {
    if (key.kind != PresentationReferenceKind.media && mediaType != null) {
      throw ArgumentError.value(
        mediaType,
        'mediaType',
        'is only supported for media nodes',
      );
    }
  }

  factory PresentationReferenceNode.fromJson(Map<String, Object?> json) {
    return PresentationReferenceNode(
      key: PresentationReferenceKey.fromJson(
        _readObject(json['key'], 'node.key'),
      ),
      label: _readString(json['label'], 'node.label'),
      defined: _readBool(json['defined'], 'node.defined'),
      mediaType: json['mediaType'] == null
          ? null
          : ProjectMediaKind.fromJson(json['mediaType']),
    );
  }

  final PresentationReferenceKey key;
  final String label;
  final bool defined;
  final ProjectMediaKind? mediaType;

  Map<String, Object?> toJson() => {
    'key': key.toJson(),
    'label': label,
    'defined': defined,
    if (mediaType != null) 'mediaType': mediaType!.id,
  };
}

final class PresentationReferenceEdge {
  PresentationReferenceEdge({
    required this.owner,
    required this.target,
    required String path,
    required this.relation,
    required this.resolution,
    Iterable<ProjectMediaKind> acceptedMediaTypes = const [],
  }) : path = _requiredString(path, 'edge.path'),
       acceptedMediaTypes = List.unmodifiable(
         acceptedMediaTypes.toSet().toList()
           ..sort((left, right) => left.id.compareTo(right.id)),
       );

  factory PresentationReferenceEdge.fromJson(Map<String, Object?> json) {
    return PresentationReferenceEdge(
      owner: PresentationReferenceKey.fromJson(
        _readObject(json['owner'], 'edge.owner'),
      ),
      target: PresentationReferenceKey.fromJson(
        _readObject(json['target'], 'edge.target'),
      ),
      path: _readString(json['path'], 'edge.path'),
      relation: _readEnum(
        PresentationReferenceRelation.values,
        json['relation'],
        'edge.relation',
      ),
      resolution: _readEnum(
        PresentationReferenceResolution.values,
        json['resolution'],
        'edge.resolution',
      ),
      acceptedMediaTypes:
          (json['acceptedMediaTypes'] == null
                  ? const <Object?>[]
                  : _readList(
                      json['acceptedMediaTypes'],
                      'edge.acceptedMediaTypes',
                    ))
              .map(ProjectMediaKind.fromJson),
    );
  }

  final PresentationReferenceKey owner;
  final PresentationReferenceKey target;
  final String path;
  final PresentationReferenceRelation relation;
  final PresentationReferenceResolution resolution;
  final List<ProjectMediaKind> acceptedMediaTypes;

  Map<String, Object?> toJson() => {
    'owner': owner.toJson(),
    'target': target.toJson(),
    'path': path,
    'relation': relation.name,
    'resolution': resolution.name,
    if (acceptedMediaTypes.isNotEmpty)
      'acceptedMediaTypes': acceptedMediaTypes
          .map((type) => type.id)
          .toList(growable: false),
  };
}

final class PresentationReferenceDiagnostic {
  PresentationReferenceDiagnostic({
    required String code,
    required this.severity,
    required String message,
    required String action,
    required this.target,
    this.owner,
    required String path,
  }) : code = _requiredString(code, 'diagnostic.code'),
       message = _requiredString(message, 'diagnostic.message'),
       action = _requiredString(action, 'diagnostic.action'),
       path = _requiredString(path, 'diagnostic.path');

  factory PresentationReferenceDiagnostic.fromJson(Map<String, Object?> json) {
    return PresentationReferenceDiagnostic(
      code: _readString(json['code'], 'diagnostic.code'),
      severity: _readEnum(
        PresentationReferenceSeverity.values,
        json['severity'],
        'diagnostic.severity',
      ),
      message: _readString(json['message'], 'diagnostic.message'),
      action: _readString(json['action'], 'diagnostic.action'),
      target: PresentationReferenceKey.fromJson(
        _readObject(json['target'], 'diagnostic.target'),
      ),
      owner: json['owner'] == null
          ? null
          : PresentationReferenceKey.fromJson(
              _readObject(json['owner'], 'diagnostic.owner'),
            ),
      path: _readString(json['path'], 'diagnostic.path'),
    );
  }

  final String code;
  final PresentationReferenceSeverity severity;
  final String message;
  final String action;
  final PresentationReferenceKey target;
  final PresentationReferenceKey? owner;
  final String path;

  Map<String, Object?> toJson() => {
    'code': code,
    'severity': severity.name,
    'message': message,
    'action': action,
    'target': target.toJson(),
    if (owner != null) 'owner': owner!.toJson(),
    'path': path,
  };
}

final class PresentationReferencePreflight {
  PresentationReferencePreflight(
    Iterable<PresentationReferenceDiagnostic> diagnostics,
  ) : diagnostics = List.unmodifiable(diagnostics);

  final List<PresentationReferenceDiagnostic> diagnostics;

  bool get canPublish => diagnostics.isEmpty;
}

final class PresentationReferenceDeletionPlan {
  PresentationReferenceDeletionPlan({
    required this.target,
    required Iterable<PresentationReferenceEdge> usages,
    required this.diagnostic,
  }) : usages = List.unmodifiable(usages);

  final PresentationReferenceKey target;
  final List<PresentationReferenceEdge> usages;
  final PresentationReferenceDiagnostic? diagnostic;

  bool get canDelete => usages.isEmpty;

  Map<String, Object?> toJson() => {
    'target': target.toJson(),
    'canDelete': canDelete,
    'usages': usages.map((usage) => usage.toJson()).toList(growable: false),
    if (diagnostic != null) 'diagnostic': diagnostic!.toJson(),
  };
}

final class PresentationReferenceGraph {
  PresentationReferenceGraph._({
    required Iterable<PresentationReferenceNode> nodes,
    required Iterable<PresentationReferenceEdge> edges,
    required Iterable<PresentationReferenceDiagnostic> diagnostics,
  }) : nodes = List.unmodifiable(nodes.toList()..sort(_compareNodes)),
       edges = List.unmodifiable(edges.toList()..sort(_compareEdges)),
       diagnostics = List.unmodifiable(
         diagnostics.toList()..sort(_compareDiagnostics),
       ) {
    _nodesByKey = Map.unmodifiable({
      for (final node in this.nodes) node.key: node,
    });
    if (_nodesByKey.length != this.nodes.length) {
      throw const FormatException('Reference graph contains duplicate nodes');
    }
    for (final edge in this.edges) {
      if (!_nodesByKey.containsKey(edge.owner) ||
          !_nodesByKey.containsKey(edge.target)) {
        throw const FormatException('Reference graph edge has an unknown node');
      }
    }
  }

  factory PresentationReferenceGraph.build({
    Iterable<PresentationCinematicAsset> cinematics = const [],
    Iterable<SceneAsset> scenes = const [],
    ProjectMediaCatalog? mediaCatalog,
    Iterable<ProjectMediaSourceAssetDefinition> sourceAssets = const [],
  }) {
    final builder = _PresentationReferenceGraphBuilder();
    builder.addCinematics(cinematics);
    builder.addScenes(scenes);
    builder.addSourceAssets(sourceAssets);
    if (mediaCatalog != null) builder.addMediaCatalog(mediaCatalog);
    return builder.build();
  }

  factory PresentationReferenceGraph.fromJson(Map<String, Object?> json) {
    final nodes = _readList(json['nodes'], 'nodes')
        .map(
          (item) =>
              PresentationReferenceNode.fromJson(_readObject(item, 'nodes[]')),
        )
        .toList(growable: false);
    final edges = _readList(json['edges'], 'edges')
        .map(
          (item) =>
              PresentationReferenceEdge.fromJson(_readObject(item, 'edges[]')),
        )
        .toList(growable: false);
    final diagnostics = _readList(json['diagnostics'], 'diagnostics')
        .map(
          (item) => PresentationReferenceDiagnostic.fromJson(
            _readObject(item, 'diagnostics[]'),
          ),
        )
        .toList(growable: false);
    return PresentationReferenceGraph._(
      nodes: nodes,
      edges: edges,
      diagnostics: diagnostics,
    );
  }

  final List<PresentationReferenceNode> nodes;
  final List<PresentationReferenceEdge> edges;
  final List<PresentationReferenceDiagnostic> diagnostics;
  late final Map<PresentationReferenceKey, PresentationReferenceNode>
  _nodesByKey;

  PresentationReferencePreflight get preflight =>
      PresentationReferencePreflight(diagnostics);

  PresentationReferenceNode? nodeFor(PresentationReferenceKey key) =>
      _nodesByKey[key];

  List<PresentationReferenceEdge> usagesOf(PresentationReferenceKey target) {
    return List.unmodifiable(edges.where((edge) => edge.target == target));
  }

  PresentationReferenceDeletionPlan planDeletion(
    PresentationReferenceKey target,
  ) {
    final node = nodeFor(target);
    if (node == null || !node.defined) {
      throw ArgumentError.value(target.toJson(), 'target', 'is not defined');
    }
    final usages = usagesOf(target);
    return PresentationReferenceDeletionPlan(
      target: target,
      usages: usages,
      diagnostic: usages.isEmpty
          ? null
          : PresentationReferenceDiagnostic(
              code: PresentationReferenceDiagnosticCodes.resourceInUse,
              severity: PresentationReferenceSeverity.error,
              message:
                  'The resource is still referenced by ${usages.length} usage(s).',
              action:
                  'Replace or remove every listed usage before deleting it.',
              target: target,
              path: 'referenceGraph.${target.kind.name}[${target.id}]',
            ),
    );
  }

  Map<String, Object?> toJson() => {
    'nodes': nodes.map((node) => node.toJson()).toList(growable: false),
    'edges': edges.map((edge) => edge.toJson()).toList(growable: false),
    'diagnostics': diagnostics
        .map((diagnostic) => diagnostic.toJson())
        .toList(growable: false),
  };
}

final class _PendingReferenceEdge {
  _PendingReferenceEdge({
    required this.owner,
    required this.target,
    required this.path,
    required this.relation,
    required this.acceptedMediaTypes,
  });

  final PresentationReferenceKey owner;
  final PresentationReferenceKey target;
  final String path;
  final PresentationReferenceRelation relation;
  final Set<ProjectMediaKind> acceptedMediaTypes;
}

final class _PresentationReferenceGraphBuilder {
  final Map<PresentationReferenceKey, PresentationReferenceNode> _nodes = {};
  final List<_PendingReferenceEdge> _pendingEdges = [];
  final List<PresentationReferenceDiagnostic> _diagnostics = [];

  void addCinematics(Iterable<PresentationCinematicAsset> source) {
    final cinematics = source.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (final cinematic in cinematics) {
      final owner = PresentationReferenceKey.presentationCinematic(
        cinematic.id,
      );
      _define(owner, cinematic.title);
      for (final track in cinematic.tracks) {
        for (final clip in track.clips) {
          final path =
              'presentationCinematics[${cinematic.id}].tracks[${track.id}]'
              '.clips[${clip.id}]';
          switch (clip) {
            case PresentationVisualClip():
              _reference(
                owner: owner,
                target: PresentationReferenceKey.media(clip.resourceId),
                path: '$path.resourceId',
                relation: PresentationReferenceRelation.clipMedia,
                acceptedMediaTypes: {
                  ProjectMediaKind.image,
                  ProjectMediaKind.video,
                },
              );
            case PresentationAudioClip():
              _reference(
                owner: owner,
                target: PresentationReferenceKey.media(clip.resourceId),
                path: '$path.resourceId',
                relation: PresentationReferenceRelation.clipMedia,
                acceptedMediaTypes: {ProjectMediaKind.audio},
              );
            case PresentationCaptionClip():
              _reference(
                owner: owner,
                target: PresentationReferenceKey.media(clip.captionId),
                path: '$path.captionId',
                relation: PresentationReferenceRelation.clipMedia,
                acceptedMediaTypes: {ProjectMediaKind.captions},
              );
            case PresentationMarkerClip(
              markerKind: PresentationMarkerKind.interactionCue,
            ):
              _define(
                PresentationReferenceKey.interactionCue(
                  clip.id,
                  presentationCinematicId: cinematic.id,
                ),
                clip.label,
              );
            case PresentationMarkerClip():
              break;
          }
        }
      }
    }
  }

  void addScenes(Iterable<SceneAsset> source) {
    final scenes = source.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (final scene in scenes) {
      final owner = PresentationReferenceKey.scene(scene.id);
      _define(owner, scene.name);
      for (final node in scene.graph.nodes) {
        if (node.payload case final ScenePresentationCinematicPayload payload) {
          _reference(
            owner: owner,
            target: PresentationReferenceKey.presentationCinematic(
              payload.presentationCinematicId,
            ),
            path:
                'scenes[${scene.id}].graph.nodes[${node.id}]'
                '.payload.presentationCinematicId',
            relation: PresentationReferenceRelation.sceneCinematic,
          );
        }
      }
    }
  }

  void addSourceAssets(Iterable<ProjectMediaSourceAssetDefinition> source) {
    final definitions = source.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (final definition in definitions) {
      _define(PresentationReferenceKey.asset(definition.id), definition.label);
    }
  }

  void addMediaCatalog(ProjectMediaCatalog catalog) {
    for (final media in catalog.entries) {
      _define(
        PresentationReferenceKey.media(media.id),
        media.label,
        mediaType: media.kind,
      );
    }
    for (final media in catalog.entries) {
      final owner = PresentationReferenceKey.media(media.id);
      final path = 'projectMedia[${media.id}]';
      _reference(
        owner: owner,
        target: PresentationReferenceKey.asset(media.sourceAssetId),
        path: '$path.sourceAssetId',
        relation: PresentationReferenceRelation.mediaSource,
      );
      if (media.posterMediaId case final posterMediaId?) {
        _reference(
          owner: owner,
          target: PresentationReferenceKey.media(posterMediaId),
          path: '$path.posterMediaId',
          relation: PresentationReferenceRelation.mediaPoster,
          acceptedMediaTypes: {ProjectMediaKind.image, ProjectMediaKind.poster},
        );
      }
      for (var index = 0; index < media.captionMediaIds.length; index++) {
        _reference(
          owner: owner,
          target: PresentationReferenceKey.media(media.captionMediaIds[index]),
          path: '$path.captionMediaIds[$index]',
          relation: PresentationReferenceRelation.mediaCaptions,
          acceptedMediaTypes: {ProjectMediaKind.captions},
        );
      }
      for (var index = 0; index < media.captions.length; index++) {
        _reference(
          owner: owner,
          target: PresentationReferenceKey.media(media.captions[index].mediaId),
          path: '$path.captions[$index].mediaId',
          relation: PresentationReferenceRelation.mediaCaptions,
          acceptedMediaTypes: {ProjectMediaKind.captions},
        );
      }
      if (media.fallbackMediaId case final fallbackMediaId?) {
        _reference(
          owner: owner,
          target: PresentationReferenceKey.media(fallbackMediaId),
          path: '$path.fallbackMediaId',
          relation: PresentationReferenceRelation.mediaFallback,
          acceptedMediaTypes: _fallbackMediaKinds(media.kind),
        );
      }
    }
  }

  PresentationReferenceGraph build() {
    final edges = <PresentationReferenceEdge>[];
    for (final pending in _pendingEdges) {
      final owner = _nodes[pending.owner]!;
      final target = _nodes[pending.target]!;
      if (!owner.defined) {
        _diagnostics.add(
          _missingDiagnostic(
            owner: null,
            target: owner.key,
            path: pending.path,
          ),
        );
      }
      final resolution = !target.defined
          ? PresentationReferenceResolution.missing
          : pending.acceptedMediaTypes.isNotEmpty &&
                !pending.acceptedMediaTypes.contains(target.mediaType)
          ? PresentationReferenceResolution.incompatible
          : PresentationReferenceResolution.resolved;
      final edge = PresentationReferenceEdge(
        owner: pending.owner,
        target: pending.target,
        path: pending.path,
        relation: pending.relation,
        resolution: resolution,
        acceptedMediaTypes: pending.acceptedMediaTypes,
      );
      edges.add(edge);
      switch (resolution) {
        case PresentationReferenceResolution.resolved:
          break;
        case PresentationReferenceResolution.missing:
          _diagnostics.add(
            _missingDiagnostic(
              owner: edge.owner,
              target: edge.target,
              path: edge.path,
            ),
          );
        case PresentationReferenceResolution.incompatible:
          _diagnostics.add(
            PresentationReferenceDiagnostic(
              code: PresentationReferenceDiagnosticCodes.mediaUnsupported,
              severity: PresentationReferenceSeverity.error,
              message:
                  'The referenced media type is incompatible with this usage.',
              action:
                  'Select a media with one of the accepted types: '
                  '${edge.acceptedMediaTypes.map((type) => type.id).join(', ')}.',
              target: edge.target,
              owner: edge.owner,
              path: edge.path,
            ),
          );
      }
    }
    _diagnostics.addAll(_fallbackCycleDiagnostics(edges));
    return PresentationReferenceGraph._(
      nodes: _nodes.values,
      edges: edges,
      diagnostics: _deduplicateDiagnostics(_diagnostics),
    );
  }

  void _define(
    PresentationReferenceKey key,
    String label, {
    ProjectMediaKind? mediaType,
  }) {
    _validateKey(key);
    final normalizedLabel = _requiredString(label, 'definition.label');
    final existing = _nodes[key];
    if (existing?.defined ?? false) {
      _diagnostics.add(
        PresentationReferenceDiagnostic(
          code: PresentationReferenceDiagnosticCodes.referenceAmbiguous,
          severity: PresentationReferenceSeverity.error,
          message: 'The resource has more than one definition.',
          action: 'Keep exactly one definition for this resource identity.',
          target: key,
          path: 'referenceGraph.${key.kind.name}[${key.id}]',
        ),
      );
      return;
    }
    _nodes[key] = PresentationReferenceNode(
      key: key,
      label: normalizedLabel,
      defined: true,
      mediaType: mediaType,
    );
  }

  void _reference({
    required PresentationReferenceKey owner,
    required PresentationReferenceKey target,
    required String path,
    required PresentationReferenceRelation relation,
    Set<ProjectMediaKind> acceptedMediaTypes = const {},
  }) {
    _ensureNode(owner);
    _ensureNode(target);
    _pendingEdges.add(
      _PendingReferenceEdge(
        owner: owner,
        target: target,
        path: path,
        relation: relation,
        acceptedMediaTypes: acceptedMediaTypes,
      ),
    );
  }

  void _ensureNode(PresentationReferenceKey key) {
    _validateKey(key);
    _nodes.putIfAbsent(
      key,
      () => PresentationReferenceNode(key: key, label: key.id, defined: false),
    );
  }

  void _validateKey(PresentationReferenceKey key) {
    _requiredString(key.id, 'referenceKey.id');
    if (key.parentId case final parentId?) {
      _requiredString(parentId, 'referenceKey.parentId');
    }
  }
}

PresentationReferenceDiagnostic _missingDiagnostic({
  required PresentationReferenceKey? owner,
  required PresentationReferenceKey target,
  required String path,
}) {
  final media = target.kind == PresentationReferenceKind.media;
  final sourceAsset = target.kind == PresentationReferenceKind.asset;
  return PresentationReferenceDiagnostic(
    code: sourceAsset
        ? PresentationReferenceDiagnosticCodes.mediaSourceMissing
        : media
        ? PresentationReferenceDiagnosticCodes.mediaMissing
        : PresentationReferenceDiagnosticCodes.referenceMissing,
    severity: PresentationReferenceSeverity.error,
    message: sourceAsset
        ? 'The physical source asset for this media does not exist.'
        : media
        ? 'The referenced presentation media does not exist.'
        : 'The referenced presentation resource does not exist.',
    action: sourceAsset
        ? 'Import a source asset or replace the media source before publication.'
        : media
        ? 'Select an existing media or import it before publication.'
        : 'Select an existing presentation resource before publication.',
    target: target,
    owner: owner,
    path: path,
  );
}

Set<ProjectMediaKind> _fallbackMediaKinds(ProjectMediaKind source) {
  if (source == ProjectMediaKind.video) {
    return {
      ProjectMediaKind.video,
      ProjectMediaKind.image,
      ProjectMediaKind.poster,
    };
  }
  if (source == ProjectMediaKind.image || source == ProjectMediaKind.poster) {
    return {ProjectMediaKind.image, ProjectMediaKind.poster};
  }
  return {source};
}

List<PresentationReferenceDiagnostic> _fallbackCycleDiagnostics(
  Iterable<PresentationReferenceEdge> source,
) {
  final adjacency = <PresentationReferenceKey, Set<PresentationReferenceKey>>{};
  for (final edge in source) {
    if (edge.relation != PresentationReferenceRelation.mediaFallback ||
        edge.resolution != PresentationReferenceResolution.resolved) {
      continue;
    }
    adjacency.putIfAbsent(edge.owner, () => {}).add(edge.target);
  }
  final cyclic = adjacency.keys.where((key) {
    final visited = <PresentationReferenceKey>{};
    final pending = <PresentationReferenceKey>[
      ...adjacency[key] ?? const <PresentationReferenceKey>{},
    ];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (current == key) return true;
      if (!visited.add(current)) continue;
      pending.addAll(adjacency[current] ?? const {});
    }
    return false;
  }).toList()..sort(_compareKeys);
  return [
    for (final key in cyclic)
      PresentationReferenceDiagnostic(
        code: PresentationReferenceDiagnosticCodes.referenceCycle,
        severity: PresentationReferenceSeverity.error,
        message: 'The presentation media fallback chain contains a cycle.',
        action: 'Remove one fallback link so the chain terminates.',
        target: key,
        path: 'presentationMedia[${key.id}].fallbackMediaId',
      ),
  ];
}

List<PresentationReferenceDiagnostic> _deduplicateDiagnostics(
  Iterable<PresentationReferenceDiagnostic> source,
) {
  final identities = <String>{};
  return [
    for (final diagnostic in source)
      if (identities.add(
        '${diagnostic.code}|${diagnostic.owner?.toJson()}|'
        '${diagnostic.target.toJson()}|${diagnostic.path}',
      ))
        diagnostic,
  ];
}

int _compareKeys(
  PresentationReferenceKey left,
  PresentationReferenceKey right,
) {
  var result = left.kind.name.compareTo(right.kind.name);
  if (result != 0) return result;
  result = left.id.compareTo(right.id);
  if (result != 0) return result;
  return (left.parentId ?? '').compareTo(right.parentId ?? '');
}

int _compareNodes(
  PresentationReferenceNode left,
  PresentationReferenceNode right,
) => _compareKeys(left.key, right.key);

int _compareEdges(
  PresentationReferenceEdge left,
  PresentationReferenceEdge right,
) {
  var result = _compareKeys(left.owner, right.owner);
  if (result != 0) return result;
  result = _compareKeys(left.target, right.target);
  if (result != 0) return result;
  result = left.path.compareTo(right.path);
  if (result != 0) return result;
  return left.relation.name.compareTo(right.relation.name);
}

int _compareDiagnostics(
  PresentationReferenceDiagnostic left,
  PresentationReferenceDiagnostic right,
) {
  var result = left.code.compareTo(right.code);
  if (result != 0) return result;
  result = _compareKeys(left.target, right.target);
  if (result != 0) return result;
  final leftOwner = left.owner;
  final rightOwner = right.owner;
  if (leftOwner == null && rightOwner != null) return -1;
  if (leftOwner != null && rightOwner == null) return 1;
  if (leftOwner != null && rightOwner != null) {
    result = _compareKeys(leftOwner, rightOwner);
    if (result != 0) return result;
  }
  return left.path.compareTo(right.path);
}

String _requiredString(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized != value) {
    throw ArgumentError.value(value, field, 'must be nonblank and trimmed');
  }
  return normalized;
}

String _readString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw FormatException('$field must be a nonblank trimmed string');
  }
  return value;
}

String? _readOptionalString(Object? value, String field) {
  if (value == null) return null;
  return _readString(value, field);
}

bool _readBool(Object? value, String field) {
  if (value is! bool) throw FormatException('$field must be a boolean');
  return value;
}

Map<String, Object?> _readObject(Object? value, String field) {
  if (value is! Map) throw FormatException('$field must be an object');
  return Map<String, Object?>.from(value);
}

List<Object?> _readList(Object? value, String field) {
  if (value is! List) throw FormatException('$field must be a list');
  return List<Object?>.from(value);
}

T _readEnum<T extends Enum>(Iterable<T> values, Object? value, String field) {
  if (value is! String) throw FormatException('$field must be a string');
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw FormatException('$field has an unsupported value');
}
