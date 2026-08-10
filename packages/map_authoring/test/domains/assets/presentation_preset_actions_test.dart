import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  group('presentation preset authoring', () {
    test('canonical dispatcher exposes the complete preset action family', () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll(<String>{
          'presentation.preset.import_plan',
          'presentation.preset.import_apply',
          'presentation.preset.export',
          'presentation.preset.delete_plan',
          'presentation.preset.delete_apply',
        }),
      );
    });

    test('exports the current profile and records it in the project library',
        () async {
      final store = MemoryArtifactStore(maximumArtifactBytes: 1 << 20);
      final snapshot = _snapshot(
        presentation: const ProjectPresentationProfile(
          branding: ProjectBrandingProfile(layoutVariant: 'cinematic'),
        ),
      );
      final action = PresentationPresetActions(artifactStore: store);

      final draft = await action.build(
        _context(
          snapshot,
          actionId: 'presentation.preset.export',
          parameters: const <String, Object?>{
            'presetId': 'night-train',
            'label': 'Train de nuit',
            'description': 'Présentation sombre et cinématique.',
            'licenses': <String, Object?>{},
          },
        ),
      );

      final projected = _projectedManifest(draft);
      expect(projected.presentationPresets.single.id, 'night-train');
      expect(draft.artifacts, hasLength(1));
      final bytes = await store.read(draft.artifacts.single.uri);
      final pack = const PresentationPresetPackCodec().decode(bytes);
      expect(pack.manifest.id, 'night-train');
      expect(pack.profile, snapshot.manifest.presentation);
    });

    test('plans and applies a staged pack atomically', () async {
      final store = MemoryArtifactStore(maximumArtifactBytes: 1 << 20);
      final profile = ProjectPresentationProfile(
        theme: safeProjectSemanticTheme,
        layouts: suggestedProjectPresentationLayouts('centered'),
      );
      final bytes = const PresentationPresetPackCodec().encode(
        ProjectPresentationPresetPack(
          manifest: PresentationPresetPackManifest(
            id: 'safe-adventure',
            label: 'Aventure sûre',
            description: 'Palette et placements sûrs.',
            compatibility: const PresentationPresetCompatibility(
              minimumProfileSchemaVersion: 4,
              maximumProfileSchemaVersion: 4,
            ),
          ),
          profile: profile,
        ),
      );
      final artifact = await store.put(bytes);
      final snapshot = _snapshot();
      final action = PresentationPresetActions(artifactStore: store);

      final planned = await action.build(
        _context(
          snapshot,
          actionId: 'presentation.preset.import_plan',
          dryRun: true,
          parameters: <String, Object?>{
            'artifactHandle': artifact.reference.handle,
          },
        ),
      );
      final applied = await action.build(
        _context(
          snapshot,
          actionId: 'presentation.preset.import_apply',
          parameters: <String, Object?>{
            'artifactHandle': artifact.reference.handle,
          },
        ),
      );

      expect(_projectedManifest(planned), _projectedManifest(applied));
      expect(_projectedManifest(applied).presentation, profile);
      expect(
        _projectedManifest(applied).presentationPresets.single.id,
        'safe-adventure',
      );
      expect(applied.preview['staged'], isTrue);
    });

    test('requires plan and apply requests to use their matching mode',
        () async {
      final store = MemoryArtifactStore(maximumArtifactBytes: 1 << 20);
      final snapshot = _snapshot();
      final action = PresentationPresetActions(artifactStore: store);

      expect(
        () => action.build(
          _context(
            snapshot,
            actionId: 'presentation.preset.delete_plan',
            parameters: const <String, Object?>{'presetId': 'missing'},
          ),
        ),
        throwsA(
          isA<PresentationPresetAuthoringException>().having(
            (error) => error.code,
            'code',
            'presentation.preset.plan_requires_dry_run',
          ),
        ),
      );
    });

    test('queries project presentation presets as first-class resources', () {
      const record = ProjectPresentationPresetRecord(
        id: 'classic',
        label: 'Classique',
        description: 'Présentation classique.',
        profile: ProjectPresentationProfile(),
      );
      final snapshot = _snapshotWithManifest(
        const ProjectManifest(
          name: 'Preset query',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          presentationPresets: <ProjectPresentationPresetRecord>[record],
        ),
      );

      final page = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'projectPresentationPreset',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
        ),
      );

      expect(page.totalAvailable, 1);
      expect(page.items.single['id'], 'classic');
      expect(page.items.single['profile'], record.profile.toJson());
    });
  });
}

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
  bool dryRun = false,
}) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'request_${actionId.replaceAll('.', '_')}',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'workspace_test',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'key_${actionId.replaceAll('.', '_')}',
        dryRun: dryRun,
      ),
      planId: 'plan_${actionId.replaceAll('.', '_')}',
      seed: 42,
    );

ProjectSnapshot _snapshot({ProjectPresentationProfile? presentation}) {
  final manifest = ProjectManifest(
    name: 'Preset fixture',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    presentation: presentation,
  );
  return _snapshotWithManifest(manifest);
}

ProjectSnapshot _snapshotWithManifest(ProjectManifest manifest) {
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  final revision = computeNarrativeProjectFingerprint(
    <NarrativeProjectFingerprintEntry>[
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: bytes,
      ),
    ],
  );
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('preset_project'),
    revision: revision,
    manifest: manifest,
    maps: const <MapData>[],
    resourceFingerprints: <String, String>{'project': revision},
    resourceBytes: <String, List<int>>{'project': bytes},
  );
}

ProjectManifest _projectedManifest(AuthoringMutationDraft draft) {
  final bytes = draft.changeSet.changes
      .singleWhere((change) => change.resource.kind == 'project')
      .afterBytes!;
  return ProjectManifest.fromJson(
    Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
  );
}
