import 'dart:async';

import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_failure_routing.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_identity_controller.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_recovery.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/features/verification/application/studio_failure_diagnosis.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';

void main() {
  Future<void> settle(bool Function() done) async {
    for (var index = 0; index < 200 && !done(); index++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(done(), isTrue);
  }

  Future<
    ({
      MapWorkspaceController maps,
      _Maps port,
      ProjectVisualsController weather,
    })
  >
  openMapWeather() async {
    final port = _Maps();
    final maps = MapWorkspaceController(scopedMapSession, port);
    addTearDown(maps.dispose);
    await maps.initialize();
    final weather = maps.weatherDraftFor(maps.active!)!;
    await settle(() => weather.saved != null && !weather.loading);
    return (maps: maps, port: port, weather: weather);
  }

  List<ProjectSettingsRecoveryTarget> mapTargets(MapWorkspaceController maps) =>
      projectSettingsRecoveryTargets(
        maps: [
          for (final document in maps.documents.values)
            if (document.weatherVisuals case final owner?)
              (
                mapId: document.base.mapId,
                name: document.current.name,
                owner: owner,
              ),
        ],
      );

  ProjectSettingsRecoveryTarget byId(
    List<ProjectSettingsRecoveryTarget> targets,
    String id,
  ) => targets.singleWhere((target) => target.id == id);

  for (final size in ['Size(1500.0, 1100.0)', 'Size(700.0, 900.0)']) {
    test(
      'retired settings retain map drafts and the real exit guard $size',
      () async {
        final (:maps, :port, :weather) = await openMapWeather();
        final document = maps.active!;
        document.commit(document.current.copyWith(name: 'Brouillon conservé'));
        final history = document.undoToken;
        weather.edit(
          weather.preview.value.set(
            SpatialVisualParameter.weatherKind,
            'storm',
          ),
        );
        weather.reportInvalid(
          SpatialVisualParameter.fieldOfViewDegrees,
          'invalide',
        );
        weather.reportInvalid(
          SpatialVisualParameter.weatherIntensity,
          'météo invalide',
        );
        final targets = mapTargets(maps);
        expect(targets.map((target) => target.id), [
          'map-first-image',
          'map-first-timeWeather',
        ]);
        final image = byId(targets, 'map-first-image');
        expect(image.label, startsWith('Image et caméra · Carte « '));
        expect(
          image.consequence,
          'La dernière version chargée de cette rubrique sera reprise.',
        );
        expect(projectSettingsRecoveryPending(image), isTrue);
        expect(projectSettingsRecoveryAvailable(image), isTrue);

        expect(
          projectSettingsRecoveryConfirmed(
            mapTargets(maps),
            'map-first-image',
            changed: true,
          ),
          isNull,
        );
        expect(
          projectSettingsRecoveryChanged,
          'Les brouillons ont changé pendant la confirmation. Vérifiez la rubrique puis recommencez.',
        );
        expect(
          weather.invalidInputs[SpatialVisualParameter.fieldOfViewDegrees],
          'invalide',
        );
        expect(
          projectSettingsRecoveryConfirmed(
            mapTargets(maps),
            'missing',
            changed: false,
          ),
          isNull,
        );

        weather.edit(
          weather.preview.value.set(SpatialVisualParameter.weatherDensity, .7),
        );
        final current = projectSettingsRecoveryConfirmed(
          mapTargets(maps),
          'map-first-image',
          changed: false,
        )!;
        current.recover();
        expect(
          weather.invalidInputs.containsKey(
            SpatialVisualParameter.fieldOfViewDegrees,
          ),
          isFalse,
        );
        expect(
          weather.invalidInputs[SpatialVisualParameter.weatherIntensity],
          'météo invalide',
        );
        expect(
          weather.preview.value.choice(SpatialVisualParameter.weatherKind),
          'storm',
        );
        expect(
          weather.preview.value.number(SpatialVisualParameter.weatherDensity),
          .7,
        );
        expect(
          projectSettingsRecoveryOutcome(
            byId(mapTargets(maps), 'map-first-image'),
          ),
          startsWith('Le brouillon de « Image et caméra · Carte'),
        );
        final remaining = byId(mapTargets(maps), 'map-first-timeWeather');
        expect(projectSettingsRecoveryPending(remaining), isTrue);
        expect(
          projectSettingsRecoveryOutcome(remaining),
          startsWith('La rubrique « Temps et météo · Carte'),
        );
        expect(document.undoToken, history);
        expect(document.current.name, 'Brouillon conservé');
        expect(maps.active, same(document));
        expect(maps.weatherDraftFor(document), same(weather));
        expect(port.visualWrites, 0);
        expect(port.fullReads, 0);
      },
    );
  }

  for (final owner in [
    StudioFailureOwner.general,
    StudioFailureOwner.image,
    StudioFailureOwner.timeWeather,
  ]) {
    test(
      'retired settings return to export and preserve $owner diagnostics and identity guards',
      () async {
        final exporter = _Export(owner);
        final identity = ProjectIdentityController(port: exporter);
        addTearDown(identity.dispose);
        await identity.open();
        expect(
          workspaceSpaceForFailure(
            exporter.failure!.owner!,
            presentationsAvailable: false,
          ),
          WorkspaceSpace.projectSettings,
        );
        final origin = workspaceSettingsOrigin(
          WorkspaceSpace.gameExport,
          WorkspaceSpace.map,
        );
        expect(origin, WorkspaceSpace.gameExport);
        expect(
          workspaceSettingsOrigin(WorkspaceSpace.projectSettings, origin),
          WorkspaceSpace.gameExport,
        );
        expect(workspaceSettingsReturnLabel(origin), 'Retour à l’export');
        expect(
          workspaceSettingsReturnLabel(WorkspaceSpace.map),
          'Retour à la carte',
        );
        expect(owner.label, startsWith('Réglages du projet › '));

        identity.edit(title: '');
        expect(identity.blocked, isTrue);
        final general = byId(
          projectSettingsRecoveryTargets(identity: identity),
          'project-general',
        );
        expect(general.label, 'Général · Tout le projet');
        expect(projectSettingsRecoveryPending(general), isTrue);
        expect(projectSettingsRecoveryAvailable(general), isTrue);
        general.recover();
        expect(identity.draft.title, 'Titre enregistré');
        expect(identity.blocked, isFalse);
        expect(identity.dirty, isFalse);
        expect(exporter.identityWrites, 0);
        expect(
          projectSettingsRecoveryPending(
            byId(
              projectSettingsRecoveryTargets(identity: identity),
              'project-general',
            ),
          ),
          isFalse,
        );

        identity.edit(title: 'Titre conservé');
        exporter.failIdentitySave = true;
        expect(await identity.save(), isFalse);
        expect(identity.dirty, isTrue);
        expect(identity.error, contains('Conflit identité conservé'));
        exporter.failIdentitySave = false;
        expect(await identity.save(), isTrue);
        expect(identity.dirty, isFalse);
        expect(exporter.metadata!.title, 'Titre conservé');
        expect(exporter.identityWrites, 2);
      },
    );
  }

  test('failure owners route to their workspace or stay on export', () {
    expect(
      workspaceSpaceForFailure(
        StudioFailureOwner.presentations,
        presentationsAvailable: false,
      ),
      WorkspaceSpace.story,
    );
    expect(
      workspaceSpaceForFailure(
        StudioFailureOwner.presentations,
        presentationsAvailable: true,
      ),
      WorkspaceSpace.presentation,
    );
    for (final owner in [
      StudioFailureOwner.exportDestination,
      StudioFailureOwner.exportMode,
    ]) {
      expect(
        workspaceSpaceForFailure(owner, presentationsAvailable: true),
        isNull,
      );
    }
    expect(
      {
        for (final owner in [
          StudioFailureOwner.resources,
          StudioFailureOwner.pokemon,
          StudioFailureOwner.regionalMap,
          StudioFailureOwner.story,
          StudioFailureOwner.map,
          StudioFailureOwner.verification,
        ])
          owner: workspaceSpaceForFailure(owner, presentationsAvailable: true),
      },
      {
        StudioFailureOwner.resources: WorkspaceSpace.resources,
        StudioFailureOwner.pokemon: WorkspaceSpace.pokemon,
        StudioFailureOwner.regionalMap: WorkspaceSpace.regionalMap,
        StudioFailureOwner.story: WorkspaceSpace.story,
        StudioFailureOwner.map: WorkspaceSpace.map,
        StudioFailureOwner.verification: WorkspaceSpace.verification,
      },
    );
    expect(
      workspaceSettingsReturnLabel(WorkspaceSpace.verification),
      'Retour aux vérifications',
    );
    expect(
      workspaceSettingsReturnLabel(WorkspaceSpace.story),
      'Retour à l’espace précédent',
    );
  });

  test(
    'identity conflict recovery requires consent and retains the map draft',
    () async {
      final (:maps, :port, weather: _) = await openMapWeather();
      final document = maps.active!;
      document.commit(document.current.copyWith(name: 'Carte à conserver'));
      final history = document.undoToken;
      final exporter = _Export(StudioFailureOwner.general);
      final identity = ProjectIdentityController(port: exporter);
      addTearDown(identity.dispose);
      await identity.open();
      identity.edit(title: 'Titre local');
      exporter.metadata = exporter.metadata!.copyWith(
        title: 'Titre enregistré ailleurs',
      );
      exporter.identityConflict = StudioGameIdentityState(
        metadata: exporter.metadata,
        profileRevision: 'concurrent',
        contextRevision: 'context',
      );
      expect(await identity.save(), isFalse);
      final conflict = identity.conflict;
      expect(conflict, isNotNull);
      final general = byId(
        projectSettingsRecoveryTargets(identity: identity),
        'project-general',
      );
      expect(general.consequence, contains('Titre local'));
      expect(general.consequence, contains('Titre enregistré ailleurs'));
      expect(projectSettingsRecoveryAvailable(general), isTrue);
      expect(identity.conflict, same(conflict));
      expect(identity.draft.title, 'Titre local');
      projectSettingsRecoveryConfirmed(
        projectSettingsRecoveryTargets(identity: identity),
        'project-general',
        changed: false,
      )!.recover();
      expect(identity.conflict, isNull);
      expect(identity.blocked, isFalse);
      expect(identity.dirty, isFalse);
      expect(identity.draft.title, 'Titre enregistré ailleurs');
      expect(exporter.identityWrites, 1);
      expect(maps.active, same(document));
      expect(document.undoToken, history);
      expect(document.current.name, 'Carte à conserver');
      expect(document.dirty, isTrue);
      expect(port.visualWrites, 0);
    },
  );
}

class _Maps extends ScopedTestMapPort implements ProjectVisualsPort {
  int visualReads = 0, visualWrites = 0;
  bool failVisualSave = false;
  final persistedVisuals = <String, SpatialVisualPatch>{};

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final value = await super.loadMap(session, entry);
    return MapWorkspaceDocument(
      map: value.map.copyWith(
        spatialScene: MapSpatialScene(width: 2, depth: 2),
      ),
      revision: value.revision,
      mapId: entry.id,
    );
  }

  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) async {
    visualReads++;
    return ProjectVisualsState(
      profile: persistedVisuals[map?.id ?? 'project'] ?? SpatialVisualPatch(),
      revision: 'visual-$visualWrites',
    );
  }

  @override
  Future<ProjectVisualsState> saveVisuals(
    ProjectSession session,
    SpatialVisualPatch profile,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) async {
    visualWrites++;
    if (failVisualSave) throw StateError('Conflit visuel conservé');
    persistedVisuals[map?.id ?? 'project'] = profile;
    return ProjectVisualsState(
      profile: profile,
      revision: 'visual-$visualWrites',
    );
  }

  @override
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => throw UnimplementedError();
}

class _Export implements StudioGameExportPort {
  _Export(StudioFailureOwner owner)
    : failure = StudioFailureDiagnosis(
        family: StudioCheckFamily.input,
        owner: owner,
        summary: 'Réglage à corriger',
        detail: 'Diagnostic conservé',
      );

  int identityWrites = 0;
  bool failIdentitySave = false;
  StudioGameIdentityState? identityConflict;
  @override
  final StudioFailureDiagnosis? failure;
  @override
  StudioGameExportMetadata? metadata = const StudioGameExportMetadata(
    gameId: 'games.avelune.retirement',
    title: 'Titre enregistré',
    version: '1.0.0',
    author: 'Avelune',
    locale: 'fr',
    locales: 'fr',
  );
  @override
  String get projectName => 'Projet conservé';
  @override
  StudioExportStage get stage => StudioExportStage.failed;
  @override
  String? get error => failure!.summary;
  @override
  String? get warning => null;
  @override
  String? get outputPath => null;
  @override
  String? get packageSha256 => null;
  @override
  String? get sourceRevision => null;
  @override
  bool get busy => false;
  @override
  bool get canCancel => false;
  @override
  bool get canStart => true;
  @override
  bool get operationActive => false;
  @override
  Stream<void> get changes => const Stream<void>.empty();
  @override
  Future<void> load() async {}
  @override
  Future<StudioGameIdentityState> readIdentity() async =>
      StudioGameIdentityState(
        metadata: metadata,
        profileRevision: 'identity-$identityWrites',
        contextRevision: 'context',
      );
  @override
  StudioGameIdentityProblem? checkIdentity(StudioGameExportMetadata value) =>
      value.title.trim().isEmpty
      ? const StudioGameIdentityProblem(
          StudioGameIdentityField.title,
          'Titre requis',
        )
      : null;
  @override
  Future<StudioGameIdentityState> saveIdentity(
    StudioGameExportMetadata value, {
    required String expectedProfileRevision,
    required String expectedContextRevision,
  }) async {
    identityWrites++;
    if (identityConflict case final current?) {
      throw StudioGameIdentityConflict(current, contextOnly: false);
    }
    if (failIdentitySave) throw StateError('Conflit identité conservé');
    metadata = value;
    return readIdentity();
  }

  @override
  void cancel() {}
  @override
  Future<bool> export({
    required StudioGameExportMetadata metadata,
    required String outputPath,
    required bool overwriteConfirmed,
    required bool publication,
    required Future<bool> Function() prepare,
    String? Function()? preparationFailure,
    required bool Function() hasPendingChanges,
    required bool Function() isCurrentProject,
  }) => throw UnimplementedError();
  @override
  void dispose() {}
}
