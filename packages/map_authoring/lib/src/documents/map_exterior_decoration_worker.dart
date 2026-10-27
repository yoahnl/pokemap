part of 'map_exterior_decoration_authoring.dart';

typedef _ExteriorWorkerRequest = ({
  String root,
  String mapId,
  String? mapRelativePath,
  String command,
  String? expectedRevision,
  String? operationId,
  Map<String, Object?> parameters,
  String actorId,
  List<AuthoringPermissionScope> permissions,
  (ProjectResourceIdentity, MapData)? mapSeed,
  bool referencesAdmitted,
  SendPort? diagnosticsPort,
});
typedef _ExteriorWorkerResult = ({
  Object value,
  (ProjectResourceIdentity, MapData)? mapSeed,
  bool referencesAdmitted
});

extension _ExteriorDecorationWorker on LocalMapExteriorDecorationAuthoring {
  Future<Object> _runWorker(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      required String command,
      String? expectedRevision,
      String? operationId,
      Map<String, Object?> parameters = const {}}) async {
    if (_reader is! LocalProjectFileReader ||
        _faultInjector != null ||
        _observer != null) {
      throw ArgumentError(
          'Worker operations require the local reader without fault injection or an in-process observer.');
    }
    if (!_actor.allows(AuthoringPermissionScope.projectRead)) {
      throw const FormatException('project.read permission is required.');
    }
    final root = await _policy.authorizeProjectRoot(projectRoot);
    final path = mapRelativePath ?? 'maps/$mapId.json';
    final key = '$root/$path', admissionKey = '$root/$mapId';
    final request = (
      root: root,
      mapId: mapId,
      mapRelativePath: mapRelativePath,
      command: command,
      expectedRevision: expectedRevision,
      operationId: operationId,
      parameters: parameters,
      actorId: _actor.actorId,
      permissions: _actor.permissions,
      mapSeed: _maps[key],
      referencesAdmitted: _referenceAdmissions.contains(admissionKey),
      diagnosticsPort: diagnosticsPort
    );
    final result = const {'inspect', 'nativeCatalog'}.contains(command)
        ? await _spawnExteriorWorker(request)
        : await withLocalProjectWriteQueue(
            root, () => _spawnExteriorWorker(request));
    if (result.mapSeed != null) _maps[key] = result.mapSeed!;
    if (result.referencesAdmitted) _referenceAdmissions.add(admissionKey);
    return result.value;
  }
}

Future<_ExteriorWorkerResult> _spawnExteriorWorker(
        _ExteriorWorkerRequest request) =>
    Isolate.run(() => _runExteriorWorker(request));

Future<_ExteriorWorkerResult> _runExteriorWorker(
    _ExteriorWorkerRequest request) async {
  final port = request.diagnosticsPort;
  if (port == null) return _runExteriorWorkerDirect(request);
  final trace = MapAuthoringWorkerTrace(request.root);
  try {
    return await trace.run(() => _runExteriorWorkerDirect(request));
  } finally {
    port.send(trace.snapshot());
  }
}

Future<_ExteriorWorkerResult> _runExteriorWorkerDirect(
    _ExteriorWorkerRequest request) async {
  const reader = LocalProjectFileReader();
  if (await reader.canonicalizeDirectory(request.root) != request.root) {
    throw const FormatException(
        'The authorized exterior project root changed before worker execution.');
  }
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [request.root], fileReader: reader);
  final service = LocalMapExteriorDecorationAuthoring(
      policy: policy,
      actor: AuthoringActor(
          actorId: request.actorId, permissions: request.permissions));
  final path = request.mapRelativePath ?? 'maps/${request.mapId}.json';
  final key = '${request.root}/$path',
      admissionKey = '${request.root}/${request.mapId}';
  if (request.mapSeed != null) service._maps[key] = request.mapSeed!;
  if (request.referencesAdmitted) {
    service._referenceAdmissions.add(admissionKey);
  }
  final p = request.parameters;
  final Object result;
  switch (request.command) {
    case 'inspect':
      result = await service.inspect(
          projectRoot: request.root,
          mapId: request.mapId,
          mapRelativePath: request.mapRelativePath,
          sectorIds: (p['sectorIds'] as List?)?.cast<String>(),
          borderIds: (p['borderIds'] as List?)?.cast<String>());
    case 'nativeCatalog':
      result = await service.inspectNativeCatalogRevision(
          projectRoot: request.root,
          mapId: request.mapId,
          mapRelativePath: request.mapRelativePath);
    case 'undo':
      result = await service.undoReceipt(
          projectRoot: request.root,
          mapId: request.mapId,
          mapRelativePath: request.mapRelativePath,
          receiptId: p['receiptId'] as String,
          expectedRevision: request.expectedRevision!,
          operationId: request.operationId!);
    case 'redo':
      result = await service.redoReceipt(
          projectRoot: request.root,
          mapId: request.mapId,
          mapRelativePath: request.mapRelativePath,
          receiptId: p['receiptId'] as String,
          expectedRevision: request.expectedRevision!,
          operationId: request.operationId!);
    case 'map.exteriorDecoration.configure':
      result = await service.configure(
          projectRoot: request.root,
          mapId: request.mapId,
          mapRelativePath: request.mapRelativePath,
          expectedRevision: request.expectedRevision!,
          operationId: request.operationId!,
          decoration: p['decoration'] == null
              ? null
              : MapExteriorDecoration.fromJson(
                  Map<String, dynamic>.from(p['decoration'] as Map)));
    case 'map.exteriorDecoration.sector.set':
      result = await service.setSector(
          projectRoot: request.root,
          mapId: request.mapId,
          mapRelativePath: request.mapRelativePath,
          expectedRevision: request.expectedRevision!,
          operationId: request.operationId!,
          sector: ExteriorDecorationSector.fromJson(
              Map<String, dynamic>.from(p['sector'] as Map)));
    case 'map.exteriorDecoration.sector.batch':
      result = await service.setSectors(
          projectRoot: request.root,
          mapId: request.mapId,
          mapRelativePath: request.mapRelativePath,
          expectedRevision: request.expectedRevision!,
          operationId: request.operationId!,
          sectors: (p['sectors'] as List).map((v) =>
              ExteriorDecorationSector.fromJson(
                  Map<String, dynamic>.from(v as Map))),
          removeSectorIds: (p['removeSectorIds'] as List).cast<String>());
    case 'map.exteriorDecoration.sector.remove':
      result = await service.removeSector(
          projectRoot: request.root,
          mapId: request.mapId,
          mapRelativePath: request.mapRelativePath,
          expectedRevision: request.expectedRevision!,
          operationId: request.operationId!,
          sectorId: p['sectorId'] as String);
    case 'map.exteriorDecoration.border.set':
      result = await service.setBorder(
          projectRoot: request.root,
          mapId: request.mapId,
          mapRelativePath: request.mapRelativePath,
          expectedRevision: request.expectedRevision!,
          operationId: request.operationId!,
          border: ExteriorDecorationBorder.fromJson(
              Map<String, dynamic>.from(p['border'] as Map)));
    case 'map.exteriorDecoration.border.remove':
      result = await service.removeBorder(
          projectRoot: request.root,
          mapId: request.mapId,
          mapRelativePath: request.mapRelativePath,
          expectedRevision: request.expectedRevision!,
          operationId: request.operationId!,
          borderId: p['borderId'] as String);
    case 'map.exteriorDecoration.references.prepare':
      result = await service.prepareIncomingReferences(
          projectRoot: request.root,
          mapId: request.mapId,
          mapRelativePath: request.mapRelativePath,
          expectedRevision: request.expectedRevision!,
          operationId: request.operationId!);
    case 'map.exteriorDecoration.native.edit':
      result = await service.nativeEdit(
          projectRoot: request.root,
          mapId: request.mapId,
          mapRelativePath: request.mapRelativePath,
          expectedRevision: request.expectedRevision!,
          operationId: request.operationId!,
          expectedCatalogRevision: p['expectedCatalogRevision'] as String,
          edit: Map<String, Object?>.from(p['edit'] as Map));
    default:
      throw const FormatException('Unknown exterior worker command.');
  }
  final seed = service._maps[key];
  return (
    value: result,
    mapSeed: seed?.$1 == request.mapSeed?.$1 ? null : seed,
    referencesAdmitted: service._referenceAdmissions.contains(admissionKey)
  );
}
