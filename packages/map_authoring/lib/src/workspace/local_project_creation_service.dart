import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../ports/exclusive_project_directory.dart';
import '../transactions/journaled_transaction.dart';
import 'project_creation_contracts.dart';
import 'project_creation_kit.dart';
import 'project_creation_transaction.dart';
import 'clairbois_project_template.dart';
import 'clairbois_template_archive.dart';

final class LocalProjectCreationService implements ProjectCreationPort {
  const LocalProjectCreationService({
    this.checkpoint,
    this.faultInjector,
    this.clairbois = const ClairboisProjectTemplate(),
  });
  final ClairboisProjectTemplate clairbois;
  final Future<void> Function(ProjectCreationCheckpoint, String)? checkpoint;
  final AuthoringTransactionFaultInjector? faultInjector;

  @override
  Future<List<int>?> preview(ProjectCreationRequest request) {
    request.validateGeometry();
    return request.template == ProjectCreationTemplate.clairbois
        ? clairbois.preview()
        : Isolate.run(() => buildProjectCreationPreviewPng(request));
  }

  @override
  Future<String> validateDestination(ProjectCreationRequest request) async {
    request.validate();
    if (!p.isAbsolute(request.parentPath)) {
      throw const ProjectCreationException('project.destination_absolute',
          'Le dossier parent doit être un chemin absolu.');
    }
    if (await FileSystemEntity.type(request.parentPath) !=
        FileSystemEntityType.directory) {
      throw const ProjectCreationException('project.parent_unavailable',
          'Le dossier parent sélectionné est indisponible.');
    }
    final parent = await Directory(request.parentPath).resolveSymbolicLinks();
    final target = p.join(parent, request.folderName);
    if (await FileSystemEntity.type(target, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw const ProjectCreationException('project.destination_exists',
          'Ce dossier existe déjà. Choisissez un autre nom ou emplacement.');
    }
    return target;
  }

  @override
  Future<ProjectCreationReceipt> create(
    ProjectCreationRequest request, {
    void Function(ProjectCreationPhase)? onPhase,
    bool Function()? isCancelled,
    String? expectedDestination,
  }) async {
    String? reservedPath;
    try {
      onPhase?.call(ProjectCreationPhase.validating);
      final target = await validateDestination(request);
      if (expectedDestination != null && target != expectedDestination) {
        throw const ProjectCreationException('project.destination_changed',
            'La destination confirmée a changé. Préparez la création à nouveau.');
      }
      _requireActive(isCancelled);
      if (request.template == ProjectCreationTemplate.clairbois) {
        onPhase?.call(ProjectCreationPhase.downloading);
      }
      final downloaded = request.template == ProjectCreationTemplate.clairbois
          ? await clairbois.download(isCancelled: isCancelled)
          : null;
      _requireActive(isCancelled);
      onPhase?.call(ProjectCreationPhase.preparing);
      final kit = downloaded == null
          ? await Isolate.run(() => buildProjectCreationKit(request))
          : await Isolate.run(
              () => prepareClairboisCreationKit(downloaded, request));
      _requireActive(isCancelled);
      await checkpoint?.call(
          ProjectCreationCheckpoint.beforeReservation, target);
      _requireActive(isCancelled);
      final latestTarget = await validateDestination(request);
      _requireActive(isCancelled);
      if (latestTarget != target) {
        throw const ProjectCreationException('project.parent_changed',
            'Le dossier parent a changé. Sélectionnez-le à nouveau.');
      }
      onPhase?.call(ProjectCreationPhase.writing);
      createExclusiveProjectDirectory(target);
      reservedPath = target;
      await checkpoint?.call(
          ProjectCreationCheckpoint.afterReservation, target);
      await writeProjectCreationKit(target, kit, faultInjector: faultInjector);
      await checkpoint?.call(ProjectCreationCheckpoint.afterApply, target);
      onPhase?.call(ProjectCreationPhase.verifying);
      for (final entry in kit.files.entries) {
        final actual = await File(p.join(target, entry.key)).readAsBytes();
        if (!_sameBytes(actual, entry.value)) {
          throw const FormatException(
              'Un fichier créé a été modifié pendant la création.');
        }
      }
      final manifest = ProjectManifest.fromJson(
          jsonDecode(await File(p.join(target, 'project.json')).readAsString())
              as Map<String, dynamic>);
      ProjectValidator.validate(manifest);
      onPhase?.call(ProjectCreationPhase.completed);
      return ProjectCreationReceipt(projectPath: target, manifest: manifest);
    } on ProjectCreationCancelled {
      rethrow;
    } on ProjectCreationException {
      rethrow;
    } on Object catch (error) {
      throw ProjectCreationException(
          'project.creation_failed',
          reservedPath == null
              ? 'La création a échoué : $error'
              : 'La création a échoué. Le dossier réservé est conservé pour récupération : $reservedPath. $error',
          residualPath: reservedPath);
    }
  }
}

void _requireActive(bool Function()? isCancelled) {
  if (isCancelled?.call() ?? false) throw const ProjectCreationCancelled();
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
