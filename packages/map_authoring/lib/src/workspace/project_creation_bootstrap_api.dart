import 'package:map_core/map_core_domain.dart';
import 'package:path/path.dart' as p;

import '../contracts/json_contract_support.dart';
import '../security/confirmation_token.dart';
import '../support/authoring_fingerprint.dart';
import 'project_creation_contracts.dart';
import 'workspace_policy.dart';

abstract interface class ProjectCreationBootstrapApiPort {
  Future<Map<String, Object?>> templates();
  Future<Map<String, Object?>> preview(Map<String, dynamic> request);
  Future<Map<String, Object?>> create(Map<String, dynamic> request,
      {required String confirmation, bool Function()? isCancelled});
}

final class ProjectCreationBootstrapApi
    implements ProjectCreationBootstrapApiPort {
  ProjectCreationBootstrapApi({
    required WorkspacePolicy policy,
    required ProjectCreationPort creation,
    DateTime Function()? clock,
  })  : _policy = policy,
        _creation = creation,
        _confirmations =
            AuthoringConfirmationStore(clock: clock ?? DateTime.now);

  final WorkspacePolicy _policy;
  final ProjectCreationPort _creation;
  final AuthoringConfirmationStore _confirmations;

  @override
  Future<Map<String, Object?>> templates() async =>
      _creation.templateCatalog.toJson();

  @override
  Future<Map<String, Object?>> preview(Map<String, dynamic> request) async {
    final prepared = await _prepare(request);
    _confirmations.pruneExpired();
    final token = _confirmations.issue(prepared.binding);
    return {
      'actionId': 'project.create',
      'actionVersion': 1,
      'projectPath': prepared.destination,
      'request': prepared.wire,
      if (prepared.request.templateId != null)
        'templateDescriptor': _creation.templateCatalog
            .require(prepared.request.templateId!)
            .toJson(),
      'confirmation': token.wireValue,
      'undoable': false,
      'replacesExisting': false,
      'writes': prepared.request.dimension == ProjectDimension.threeD
          ? ['project.json', 'maps/first-map.json']
          : prepared.request.template == ProjectCreationTemplate.empty
              ? ['project.json']
              : prepared.request.template == ProjectCreationTemplate.catalogue
                  ? _creation.templateCatalog
                      .require(prepared.request.templateId!)
                      .projectPaths
                  : [
                      'project.json',
                      'maps/first-map.json',
                      'assets/starter.png',
                      'assets/.pokemap-assets.json',
                      'assets/.pokemap-store/<sha256>.blob'
                    ],
      'guarantee':
          'Exclusive new directory; journaled file promotion, not atomic multi-file visibility. Creation is not undoable.',
    };
  }

  @override
  Future<Map<String, Object?>> create(Map<String, dynamic> request,
      {required String confirmation, bool Function()? isCancelled}) async {
    final prepared = await _prepare(request);
    _confirmations.consume(
        AuthoringConfirmationToken.fromWireValue(confirmation),
        prepared.binding);
    final receipt = await _creation.create(prepared.request,
        isCancelled: isCancelled, expectedDestination: prepared.destination);
    return {
      'actionId': 'project.create',
      'actionVersion': 1,
      'projectPath': receipt.projectPath,
      'projectName': receipt.manifest.name,
      'tileWidth': receipt.manifest.settings.tileWidth,
      'tileHeight': receipt.manifest.settings.tileHeight,
      'mapIds': receipt.manifest.maps.map((map) => map.id).toList(),
      'undoable': false,
      'replacesExisting': false,
    };
  }

  Future<_PreparedCreation> _prepare(Map<String, dynamic> wire) async {
    rejectUnknownContractKeys(wire, const {
      'name',
      'folderName',
      'parentPath',
      'template',
      'templateId',
      'tileSize',
      'mapWidth',
      'mapHeight',
      'dimension',
      'mapInstanceRetentionPolicy',
      'spatialCamera'
    });
    final templateId =
        wire['templateId'] == null ? null : _string(wire['templateId']);
    final descriptor = wire['template'] == 'catalogue' && templateId != null
        ? _creation.templateCatalog.require(templateId)
        : null;
    final request = ProjectCreationRequest(
      name: _string(wire['name']),
      folderName: _string(wire['folderName']),
      parentPath: _string(wire['parentPath']),
      template: switch (wire['template']) {
        null || 'playable' => ProjectCreationTemplate.playable,
        'empty' => ProjectCreationTemplate.empty,
        'catalogue' => ProjectCreationTemplate.catalogue,
        _ => throw const FormatException('Invalid project template.')
      },
      templateId: templateId,
      dimension: switch (wire['dimension']) {
        null || 'twoD' => ProjectDimension.twoD,
        'threeD' => ProjectDimension.threeD,
        _ => throw const FormatException('Invalid project dimension.')
      },
      spatialCamera: wire['spatialCamera'] == null
          ? null
          : SpatialCameraProfile.fromJson(
              Map<String, dynamic>.from(wire['spatialCamera'] as Map)),
      mapInstanceRetentionPolicy:
          !wire.containsKey('mapInstanceRetentionPolicy')
              ? null
              : MapInstanceRetentionPolicy.fromJson(Map<String, dynamic>.from(
                  wire['mapInstanceRetentionPolicy'] as Map)),
      tileSize: _integer(wire['tileSize'], descriptor?.tileSize ?? 16),
      mapWidth: _integer(wire['mapWidth'], descriptor?.mapWidth ?? 20),
      mapHeight: _integer(wire['mapHeight'], descriptor?.mapHeight ?? 15),
    );
    request.validate();
    final canonicalParent =
        await _policy.authorizeProjectRoot(request.parentPath);
    final authorizedRequest = ProjectCreationRequest(
        name: request.name,
        folderName: request.folderName,
        parentPath: canonicalParent,
        template: request.template,
        templateId: request.templateId,
        dimension: request.dimension,
        spatialCamera: request.spatialCamera,
        mapInstanceRetentionPolicy: request.mapInstanceRetentionPolicy,
        tileSize: request.tileSize,
        mapWidth: request.mapWidth,
        mapHeight: request.mapHeight);
    final destination = await _creation.validateDestination(authorizedRequest);
    if (p.dirname(destination) != canonicalParent) {
      throw const ProjectCreationException('project.parent_changed',
          'The authorized parent changed while preparing creation.');
    }
    final normalized = <String, Object?>{
      'name': request.name,
      'folderName': request.folderName,
      'parentPath': request.parentPath,
      'template': request.template.name,
      if (templateId != null) 'templateId': templateId,
      'dimension': request.dimension.name,
      if (request.spatialCamera != null)
        'spatialCamera': request.spatialCamera!.toJson(),
      if (request.mapInstanceRetentionPolicy != null)
        'mapInstanceRetentionPolicy':
            request.mapInstanceRetentionPolicy!.toJson(),
      'tileSize': request.tileSize,
      'mapWidth': request.mapWidth,
      'mapHeight': request.mapHeight,
    };
    final fingerprint = computeAuthoringJsonFingerprint({
      'request': normalized,
      if (descriptor != null) 'templateDescriptor': descriptor.toJson(),
      'parent': canonicalParent,
      'target': destination
    }, logicalName: 'project-creation-confirmation.json');
    return _PreparedCreation(
        authorizedRequest,
        normalized,
        destination,
        AuthoringConfirmationBinding(
            actorId: 'project-bootstrap',
            projectId:
                'root_${computeAuthoringJsonFingerprint(canonicalParent, logicalName: 'parent').substring(7)}',
            actionId: 'project.create',
            actionVersion: 1,
            planId: 'creation_${fingerprint.substring(7)}',
            diffFingerprint: fingerprint));
  }
}

String _string(Object? value) {
  if (value is! String) throw const FormatException('String required.');
  return value;
}

int _integer(Object? value, int fallback) {
  if (value == null) return fallback;
  if (value is! int) throw const FormatException('Integer required.');
  return value;
}

final class _PreparedCreation {
  const _PreparedCreation(
      this.request, this.wire, this.destination, this.binding);
  final ProjectCreationRequest request;
  final Map<String, Object?> wire;
  final String destination;
  final AuthoringConfirmationBinding binding;
}
