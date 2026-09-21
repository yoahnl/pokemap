import 'dart:convert';
import 'package:map_core/map_core.dart';
import '../assets/presentation_media_import_actions.dart';
import '../assets/project_media_store.dart';
import '../../contracts/authoring_request.dart';
import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import 'narrative_action_support.dart';
import 'presentation_publication_snapshot.dart';
import 'presentation_publication_guards.dart';
import 'scene_actions.dart';

final class PresentationPublicationActions {
  const PresentationPublicationActions({required this.mediaImports});
  final PresentationMediaImportActions mediaImports;
  static final descriptor = AuthoringActionDescriptor(
    id: 'presentationCinematic.publish',
    version: 1,
    summary:
        'Publish a final Presentation document, staged media and exact Scene link atomically',
    inputSchemaId: 'pokemap.authoring/presentationCinematic.publish.input.v1',
    outputSchemaId: 'pokemap.authoring/presentationCinematic.publish.output.v1',
    riskLevel: AuthoringRiskLevel.medium,
    resourceKinds: const [
      'project',
      'presentationCinematic',
      'cinematicLibraryEntry',
      'scene',
      'asset',
      'presentationMedia'
    ],
    capabilityIds: const [
      'authoring.narrative.modern',
      'authoring.presentation_media'
    ],
    requiredPermissions: const [
      AuthoringPermission.projectWrite,
      AuthoringPermission.importRun
    ],
    guarantees: const [
      AuthoringGuarantee.atomic,
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable
    ],
  );
  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    final p = context.request.parameters;
    rejectUnknownNarrativeParameters(p, const {
      'cinematic',
      'expectedCinematic',
      'expectedEntry',
      'expectedMedia',
      'folderId',
      'changeFolder',
      'link',
      'imports',
    });
    if (!p.containsKey('expectedCinematic') ||
        !p.containsKey('expectedEntry')) {
      throw StateError(
          'Presentation publication requires explicit document baselines.');
    }
    final asset = decodePresentationCinematicAsset(
        narrativeObjectParameter(p, 'cinematic'));
    var snapshot = context.snapshot;
    var project = snapshot.manifest;
    validatePresentationPublicationBase(snapshot, asset.id, p);
    final changes = <AuthoringResourceChange>[];
    final diffs = <AuthoringDiffEntry>[];
    final imports = p['imports'] as List? ?? const [];
    for (final raw in imports) {
      final fields = Map<String, Object?>.from(raw as Map);
      final expectedMedia = fields.remove('expectedMedia');
      if (presentationImportAlreadyPublished(
          snapshot, fields, expectedMedia, mediaImports.artifactStore)) {
        continue;
      }
      final draft = await mediaImports.build(AuthoringPlanningContext(
        snapshot: snapshot,
        request: AuthoringRequest(
            requestId: context.request.requestId,
            actionId: 'presentationMedia.import',
            actionVersion: 1,
            workspaceHandle: context.request.workspaceHandle,
            expectedRevision: snapshot.revision,
            idempotencyKey: context.request.idempotencyKey,
            parameters: fields),
        planId: context.planId,
        seed: context.seed,
      ));
      changes.addAll(draft.changeSet.changes);
      diffs.addAll(draft.changeSet.diff.entries);
      snapshot = projectPresentationPublicationSnapshot(snapshot,
          manifest: project, changes: draft.changeSet.changes);
    }
    final link = p['link'];
    if (link is Map) {
      if (p['expectedCinematic'] != null) {
        throw StateError('Linked creation requires a new Presentation.');
      }
      final fields = Map<String, Object?>.from(link);
      final scene =
          SceneAsset.fromJson(narrativeObjectParameter(fields, 'scene'));
      project = project.copyWith(scenes: [
        for (final s in project.scenes)
          if (s.id == scene.id) scene else s
      ]);
      project = const SceneActions().createAndLinkPreSessionPresentation(
          project,
          maps: snapshot.maps,
          sceneId: scene.id,
          nodeId: narrativeStringParameter(fields, 'nodeId'),
          targetNodeId: narrativeStringParameter(fields, 'targetNodeId'),
          cinematic: asset,
          sourceAssets: presentationSourceAssets(snapshot),
          mediaCatalog: snapshot
                      .findResourceBytes(projectMediaCatalogResourceIdentity) ==
                  null
              ? ProjectMediaCatalog()
              : decodeProjectMediaCatalogBytes(
                  snapshot.resourceBytes(projectMediaCatalogResourceIdentity)),
          targetFolderId: p['folderId'] as String?,
          targetIndex: _index(project, p['folderId'] as String?));
    } else {
      project = project.copyWith(presentationCinematics: [
        for (final a in project.presentationCinematics)
          if (a.id == asset.id) asset else a,
        if (!project.presentationCinematics.any((a) => a.id == asset.id)) asset,
      ]);
      if (p['expectedCinematic'] == null || p['changeFolder'] == true) {
        project = project.copyWith(
            cinematicLibraryCatalog: const CinematicLibraryCatalogOperations()
                .placeCinematic(project.cinematicLibraryCatalog,
                    family: CinematicLibraryFamily.presentation,
                    cinematicId: asset.id,
                    targetFolderId: p['folderId'] as String?,
                    targetIndex: _index(project, p['folderId'] as String?)));
      }
    }
    final mediaBytes =
        snapshot.findResourceBytes(projectMediaCatalogResourceIdentity);
    final graph = PresentationReferenceGraph.build(
        cinematics: project.presentationCinematics,
        scenes: project.scenes,
        sourceAssets: presentationSourceAssets(snapshot),
        mediaCatalog: mediaBytes == null
            ? ProjectMediaCatalog()
            : decodeProjectMediaCatalogBytes(mediaBytes));
    final consumers = <String>{
      for (final scene in project.scenes)
        for (final node in scene.graph.nodes)
          if (node.payload
              case ScenePresentationCinematicPayload(
                :final presentationCinematicId
              ))
            if (presentationCinematicId == asset.id) scene.id
    };
    final targets = <PresentationReferenceKey>{
      PresentationReferenceKey.presentationCinematic(asset.id)
    };
    var growing = true;
    while (growing) {
      growing = false;
      for (final edge in graph.edges) {
        if (targets.contains(edge.owner) && targets.add(edge.target)) {
          growing = true;
        }
      }
    }
    final errors = graph.diagnostics
        .where((d) =>
            targets.contains(d.owner) ||
            (d.owner?.kind == PresentationReferenceKind.scene &&
                consumers.contains(d.owner?.id)))
        .toList();
    if (errors.isNotEmpty) {
      throw StateError(
          'Références invalides : ${jsonEncode(errors.map((d) => d.toJson()).toList())}');
    }
    final finalDraft = project == context.snapshot.manifest
        ? AuthoringMutationDraft(
            projectedProject: project,
            changeSet: AuthoringChangeSet.noChanges(),
            preview: {'cinematicId': asset.id})
        : narrativeProjectDraft(context.snapshot, project,
            operation: descriptor.id,
            path: '/presentationCinematics/${asset.id}',
            before: p['expectedCinematic'],
            after: encodePresentationCinematicAsset(asset),
            preview: {
                'cinematicId': asset.id,
                'linkedSceneId':
                    link is Map ? ((link['scene'] as Map?)?['id']) : null
              });
    changes.addAll(finalDraft.changeSet.changes);
    diffs.addAll(finalDraft.changeSet.diff.entries);
    if (changes.isEmpty) {
      return AuthoringMutationDraft(
          projectedProject: project,
          changeSet: AuthoringChangeSet.noChanges(),
          preview: finalDraft.preview);
    }
    return AuthoringMutationDraft(
        projectedProject: project,
        changeSet: AuthoringChangeSet(
            changes: mergePresentationPublicationChanges(changes),
            diff: AuthoringDiff(diffs)),
        preview: finalDraft.preview);
  }

  int _index(ProjectManifest project, String? folder) =>
      project.cinematicLibraryCatalog.entries
          .where((e) =>
              e.family == CinematicLibraryFamily.presentation &&
              e.folderId == folder)
          .length;
}
