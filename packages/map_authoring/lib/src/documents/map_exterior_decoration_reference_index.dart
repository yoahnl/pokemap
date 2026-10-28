part of 'map_exterior_decoration_authoring.dart';

extension MapExteriorDecorationIncomingReferences
    on LocalMapExteriorDecorationAuthoring {
  Future<MapExteriorDecorationMutation> prepareIncomingReferences({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
    required String expectedRevision,
    required String operationId,
  }) =>
      _mutate(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          expectedRevision: expectedRevision,
          operationId: operationId,
          descriptor:
              LocalMapExteriorDecorationAuthoring.prepareReferencesDescriptor,
          parameters: const {},
          prepareReferences: true,
          prepare: (context, index) async {
            if (index.definition == null) {
              throw const FormatException(
                  'Configure exterior decoration before preparing references.');
            }
            return {
              context.storageKey: index.toJson(),
              for (final summary in index.sectors.values)
                _sectorPath(mapId, summary.id):
                    (await _readSector(context, summary)).toJson(),
              for (final summary in index.borders.values)
                _borderPath(mapId, summary.id):
                    (await _readBorder(context, summary)).toJson(),
            };
          });
}

extension _ExteriorDecorationReferenceIndex
    on LocalMapExteriorDecorationAuthoring {
  Future<void> _prepareIncomingChanges(
      _DecorationContext context,
      _DecorationIndex index,
      Map<String, List<int>?> beforeImages,
      Map<String, Map<String, dynamic>?> images,
      List<AuthoringResourceChange> changes,
      List<AuthoringDiffEntry> diffs,
      String expectedRevision,
      String afterRevision,
      {required bool repairing,
      required String operationId}) async {
    final admissionPath = exteriorReferenceAdmissionPath(context.map.id);
    final admissionKey = '${context.root}/${context.map.id}';
    List<int>? admission;
    if (repairing || !_referenceAdmissions.contains(admissionKey)) {
      admission = await context.gateway.readResource(admissionPath);
      if (admission != null &&
          !_referenceAdmissionMatches(admission, context.map.id)) {
        throw const FormatException(
            'exterior.reference_index_recovery_required: invalid map admission.');
      }
      if (admission == null && index.definition != null && !repairing) {
        throw const FormatException(
            'exterior.reference_index_recovery_required: explicitly prepare incoming references for this map.');
      }
    }
    final owners = <String,
        (
      ExteriorReferenceOwner,
      Set<CatalogDefinitionKey>,
      Set<CatalogDefinitionKey>
    )>{};
    for (final image in images.entries) {
      if (image.key == context.storageKey) continue;
      final border =
          image.key.startsWith('maps/${context.map.id}.decoration/borders/');
      final id = image.key
          .substring(image.key.lastIndexOf('/') + 1, image.key.length - 5);
      final owner = ExteriorReferenceOwner(
          context.map.id, border ? 'border' : 'sector', id);
      Set<CatalogDefinitionKey> references(Map<String, dynamic>? json) =>
          json == null
              ? {}
              : border
                  ? exteriorBorderReferences(
                      ExteriorDecorationBorder.fromJson(json))
                  : exteriorSectorReferences(
                      ExteriorDecorationSector.fromJson(json));
      final before = beforeImages[image.key];
      final old = references(before == null ? null : _decode(before));
      final next = references(image.value);
      if (!repairing && old.length == next.length && old.containsAll(next)) {
        continue;
      }
      owners[owner.identity] = (owner, old, next);
    }
    if (repairing) {
      final directory =
          admissionPath.substring(0, admissionPath.lastIndexOf('/'));
      if (_reader is! ProjectDirectoryReader) {
        throw const FormatException(
            'Explicit reference preparation requires directory reads.');
      }
      for (final kind in ['sector', 'border']) {
        List<String> paths;
        try {
          paths = await (_reader as ProjectDirectoryReader).listFiles(
              projectRoot: context.root, relativeDirectory: '$directory/$kind');
        } on WorkspaceAccessException catch (e) {
          if (e.code == 'workspace.directory_missing') continue;
          rethrow;
        }
        for (final path in paths) {
          final raw = await context.gateway.readResource(path);
          if (raw == null) {
            throw const FormatException(
                'exterior.reference_index_recovery_required');
          }
          final json = _decode(raw),
              owner = ExteriorReferenceOwner.fromJson(
                  Map<String, dynamic>.from(json['owner'] as Map));
          if (owner.mapId != context.map.id ||
              exteriorReferenceOwnerPath(
                      owner.mapId, owner.unitKind, owner.unitId) !=
                  path) {
            throw const FormatException(
                'exterior.reference_index_recovery_required');
          }
          final existing = owners[owner.identity];
          owners[owner.identity] =
              (owner, _ownerReferences(json), existing?.$3 ?? {});
        }
      }
    }
    final indexImages = <CatalogDefinitionKey,
        (List<int>?, Map<String, ExteriorReferenceOwner>)>{};
    for (final entry in owners.values) {
      final owner = entry.$1;
      final ownerPath =
          exteriorReferenceOwnerPath(owner.mapId, owner.unitKind, owner.unitId);
      final beforeOwner = await context.gateway.readResource(ownerPath);
      if (beforeOwner != null &&
          ExteriorReferenceOwner.fromJson(Map<String, dynamic>.from(
                      _decode(beforeOwner)['owner'] as Map))
                  .identity !=
              owner.identity) {
        throw const FormatException(
            'exterior.reference_index_recovery_required');
      }
      final recorded = beforeOwner == null
          ? <CatalogDefinitionKey>{}
          : _ownerReferences(_decode(beforeOwner));
      if (!repairing &&
          (recorded.length != entry.$2.length ||
              !recorded.containsAll(entry.$2))) {
        throw const FormatException(
            'exterior.reference_index_recovery_required: owner references differ.');
      }
      final old = repairing ? recorded : entry.$2;
      for (final key in {...old, ...entry.$3}) {
        var current = indexImages[key];
        if (current == null) {
          final bytes = await context.gateway
              .readResource(exteriorReferenceIndexPath(key));
          final backup = bytes == null
              ? await context.gateway
                  .readResource(exteriorReferenceBackupPath(key))
              : null;
          if (bytes == null && backup != null && !repairing) {
            throw const FormatException(
                'exterior.reference_index_recovery_required: the incoming index is missing.');
          }
          current =
              (bytes, decodeExteriorReferenceOwners(bytes ?? backup, key));
          indexImages[key] = current;
        }
        if (!repairing &&
            old.contains(key) &&
            !current.$2.containsKey(owner.identity)) {
          throw const FormatException(
              'exterior.reference_index_recovery_required: missing incoming owner.');
        }
        if (entry.$3.contains(key)) {
          current.$2[owner.identity] = owner;
        } else {
          current.$2.remove(owner.identity);
        }
      }
      final afterOwner = entry.$3.isEmpty
          ? null
          : _encode({
              'schemaVersion': 1,
              'owner': owner.toJson(),
              'references': [
                for (final key in entry.$3.toList()..sort()) key.toJson()
              ]
            }, LocalMapExteriorDecorationAuthoring.maximumSectorBytes);
      _appendReferenceChange(
          context,
          ownerPath,
          beforeOwner,
          afterOwner,
          'decorationReferenceOwner',
          owner.identity,
          changes,
          diffs,
          expectedRevision,
          afterRevision);
    }
    for (final entry in indexImages.entries) {
      final path = exteriorReferenceIndexPath(entry.key),
          owners = entry.value.$2;
      final bytes = _encode(
          encodeExteriorReferenceOwners(entry.key, owners), 16 * 1024 * 1024);
      final backupPath = exteriorReferenceBackupPath(entry.key);
      final backup = await context.gateway.readResource(backupPath);
      _appendReferenceChange(
          context,
          backupPath,
          backup,
          bytes,
          'decorationReferenceBackup',
          '${entry.key.kind.name}:${entry.key.id}',
          changes,
          diffs,
          expectedRevision,
          afterRevision);
      _appendReferenceChange(
          context,
          path,
          entry.value.$1,
          bytes,
          owners.isEmpty ? 'visualReferenceIndex' : 'decorationReferenceIndex',
          '${entry.key.kind.name}:${entry.key.id}',
          changes,
          diffs,
          expectedRevision,
          afterRevision);
    }
    if (repairing ||
        (admission == null && !_referenceAdmissions.contains(admissionKey))) {
      _appendReferenceChange(
          context,
          admissionPath,
          admission,
          _encode({
            'schemaVersion': 1,
            'mapId': context.map.id,
            if (repairing) 'preparedByOperation': operationId
          }, 4096),
          'decorationReferenceAdmission',
          context.map.id,
          changes,
          diffs,
          expectedRevision,
          afterRevision);
    }
  }

  Set<CatalogDefinitionKey> _ownerReferences(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1 || json['references'] is! List) {
      throw const FormatException('exterior.reference_index_recovery_required');
    }
    return {
      for (final raw in json['references'] as List)
        CatalogDefinitionKey.fromJson(Map<String, Object?>.from(raw as Map))
    };
  }

  void _appendReferenceChange(
      _DecorationContext context,
      String path,
      List<int>? before,
      List<int>? after,
      String kind,
      String id,
      List<AuthoringResourceChange> changes,
      List<AuthoringDiffEntry> diffs,
      String beforeRevision,
      String afterRevision) {
    if (_sameBytes(before, after)) return;
    final resource = AuthoringResourceRef(kind: kind, id: id);
    changes.add(AuthoringResourceChange(
        resource: resource,
        storageKey: path,
        beforeBytes: before,
        afterBytes: after));
    diffs.add(AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: resource,
        path: '/exteriorDecoration/references',
        before: before == null ? null : _decode(before),
        after: after == null ? null : _decode(after),
        extensions: {
          'mapId': context.map.id,
          'storageKey': path,
          'documentBeforeRevision': beforeRevision,
          'documentAfterRevision': afterRevision
        }));
  }
}

bool _referenceAdmissionMatches(List<int> bytes, String mapId) {
  final json = _decode(bytes);
  return json['schemaVersion'] == 1 &&
      json['mapId'] == mapId &&
      json.keys.every((key) => const {
            'schemaVersion',
            'mapId',
            'preparedByOperation'
          }.contains(key)) &&
      (!json.containsKey('preparedByOperation') ||
          json['preparedByOperation'] is String);
}
