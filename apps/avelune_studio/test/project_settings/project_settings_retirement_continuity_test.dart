import 'dart:async';

import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/features/verification/application/studio_failure_diagnosis.dart';
import 'package:avelune_studio/presentation/features/game_export/studio_game_export_page.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_application_frame.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/scoped_map_workspace_port.dart';

void main() {
  for (final size in [const Size(1500, 1100), const Size(700, 900)]) {
    testWidgets(
      'retired settings retain map drafts and the real exit guard $size',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final port = _Maps();
        final maps = MapWorkspaceController(scopedMapSession, port);
        final home = StudioHomeNavigation();
        addTearDown(maps.dispose);
        addTearDown(home.dispose);
        Future<bool> Function()? exit;
        var visualLoads = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: MapWorkspaceScreen(
              controller: maps,
              home: home,
              loadVisuals: (_, _) async {
                visualLoads++;
                return WorkspaceTestVisuals();
              },
              runtimeBuilder: (_, _, _) => const SizedBox(),
              onClose: () async {},
              registerExitGuard: (guard) => exit = guard,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final document = maps.active!;
        final weather = maps.weatherDraftFor(document)!;
        await tester.pumpAndSettle();
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
        final visualDraft = weather.preview.value;
        final reads = List.of(port.selections);
        final visualReads = port.visualReads;
        home.navigate('projectSettings');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('project-settings-unavailable')),
          findsOneWidget,
        );
        expect(find.text('Réglages du projet indisponibles'), findsOneWidget);
        expect(find.byType(StudioApplicationFrame), findsOneWidget);
        expect(document.undoToken, history);
        expect(maps.active, same(document));
        expect(weather.preview.value, same(visualDraft));
        expect(
          weather.invalidInputs[SpatialVisualParameter.fieldOfViewDegrees],
          'invalide',
        );
        expect(port.visualReads, visualReads);
        expect(port.selections, reads);
        expect(port.fullReads, 0);
        expect(visualLoads, 1);
        await tester.ensureVisible(
          find.byKey(const ValueKey('project-settings-return')),
        );
        await tester.tap(find.byKey(const ValueKey('project-settings-return')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('project-settings-unavailable')),
          findsNothing,
        );
        expect(maps.active, same(document));
        expect(maps.weatherDraftFor(document), same(weather));
        expect(document.current.name, 'Brouillon conservé');
        final cancelled = exit!();
        await tester.pumpAndSettle();
        await tester.tap(_dialogAction('Annuler'));
        await tester.pumpAndSettle();
        expect(await cancelled, isFalse);
        expect(weather.dirty, isTrue);
        final invalid = exit!();
        await tester.pumpAndSettle();
        await tester.tap(_dialogAction('Enregistrer'));
        await tester.pumpAndSettle();
        expect(await invalid, isFalse);
        expect(
          weather.invalidInputs[SpatialVisualParameter.fieldOfViewDegrees],
          'invalide',
        );
        expect(weather.error, contains('valeurs invalides'));
        expect(port.visualWrites, 0);
        weather.reportInvalid(
          SpatialVisualParameter.weatherIntensity,
          'météo invalide',
        );
        home.navigate('projectSettings');
        await tester.pumpAndSettle();
        final recoverImage = find.byKey(
          const ValueKey('settings-recover-map-first-image'),
        );
        await tester.ensureVisible(recoverImage);
        await tester.tap(recoverImage);
        await tester.pumpAndSettle();
        expect(
          find.text('Abandonner le brouillon de cette rubrique ?'),
          findsOneWidget,
        );
        await tester.tap(_dialogAction('Conserver le brouillon'));
        await tester.pumpAndSettle();
        expect(
          weather.invalidInputs[SpatialVisualParameter.fieldOfViewDegrees],
          'invalide',
        );
        await tester.tap(recoverImage);
        await tester.pumpAndSettle();
        weather.edit(
          weather.preview.value.set(SpatialVisualParameter.weatherDensity, .7),
        );
        await tester.pump();
        await tester.tap(_dialogAction('Abandonner cette rubrique'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Les brouillons ont changé pendant la confirmation. Vérifiez la rubrique puis recommencez.',
          ),
          findsOneWidget,
        );
        expect(
          weather.invalidInputs[SpatialVisualParameter.fieldOfViewDegrees],
          'invalide',
        );
        await tester.tap(recoverImage);
        await tester.pumpAndSettle();
        await tester.tap(_dialogAction('Abandonner cette rubrique'));
        await tester.pumpAndSettle();
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
        expect(document.undoToken, history);
        expect(document.current.name, 'Brouillon conservé');
        expect(port.visualWrites, 0);
        weather.clearInvalid(SpatialVisualParameter.weatherIntensity);
        final remainingDraft = weather.preview.value;
        await tester.ensureVisible(
          find.byKey(const ValueKey('project-settings-return')),
        );
        await tester.tap(find.byKey(const ValueKey('project-settings-return')));
        await tester.pumpAndSettle();
        port.failVisualSave = true;
        final failed = exit!();
        await tester.pumpAndSettle();
        await tester.tap(_dialogAction('Enregistrer'));
        await tester.pumpAndSettle();
        expect(await failed, isFalse);
        expect(weather.dirty, isTrue);
        expect(weather.preview.value, remainingDraft);
        expect(weather.error, contains('Conflit visuel conservé'));
        expect(port.persistedVisuals, isEmpty);
        port.failVisualSave = false;
        final saved = exit!();
        await tester.pumpAndSettle();
        await tester.tap(_dialogAction('Enregistrer'));
        await tester.pumpAndSettle();
        expect(await saved, isTrue);
        expect(weather.dirty, isFalse);
        expect(port.persistedVisuals['first'], remainingDraft);
        expect(maps.active, same(document));
        expect(port.fullReads, 0);
        expect(visualLoads, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final owner in [
    StudioFailureOwner.general,
    StudioFailureOwner.image,
    StudioFailureOwner.timeWeather,
  ]) {
    testWidgets(
      'retired settings return to export and preserve $owner diagnostics and identity guards',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1500, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final port = _Maps();
        final maps = MapWorkspaceController(scopedMapSession, port);
        final home = StudioHomeNavigation();
        final exporter = _Export(owner);
        addTearDown(maps.dispose);
        addTearDown(home.dispose);
        Future<bool> Function()? exit;
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: MapWorkspaceScreen(
              controller: maps,
              home: home,
              loadVisuals: (_, _) async => WorkspaceTestVisuals(),
              runtimeBuilder: (_, _, _) => const SizedBox(),
              gameExport: exporter,
              gameExportPicker: (_) async => null,
              onClose: () async {},
              registerExitGuard: (guard) => exit = guard,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final document = maps.active;
        home.navigate('gameExport');
        await tester.pumpAndSettle();
        final page = tester.widget<StudioGameExportPage>(
          find.byType(StudioGameExportPage),
        );
        final identity = page.identity!;
        identity.edit(title: '');
        await tester.pumpAndSettle();
        expect(identity.blocked, isTrue);
        final edit = find.byKey(const ValueKey('export-edit-identity'));
        await tester.ensureVisible(edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('project-settings-unavailable')),
          findsOneWidget,
        );
        expect(find.text('Retour à l’export'), findsOneWidget);
        expect(identity.draft.title, '');
        expect(identity.blocked, isTrue);
        await tester.ensureVisible(
          find.byKey(const ValueKey('project-settings-return')),
        );
        await tester.tap(find.byKey(const ValueKey('project-settings-return')));
        await tester.pumpAndSettle();
        var returned = tester.widget<StudioGameExportPage>(
          find.byType(StudioGameExportPage),
        );
        expect(returned.identity, same(identity));
        expect(returned.hasPendingChanges(), isTrue);
        final preparation = returned.prepare();
        await tester.pumpAndSettle();
        await tester.tap(_dialogAction('Enregistrer puis exporter'));
        await tester.pumpAndSettle();
        expect(await preparation, isFalse);
        expect(identity.draft.title, '');
        expect(exporter.identityWrites, 0);
        final closing = exit!();
        await tester.pumpAndSettle();
        await tester.tap(_dialogAction('Enregistrer'));
        await tester.pumpAndSettle();
        expect(await closing, isFalse);
        expect(identity.blocked, isTrue);
        await tester.ensureVisible(edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        final recoverIdentity = find.byKey(
          const ValueKey('settings-recover-project-general'),
        );
        await tester.ensureVisible(recoverIdentity);
        await tester.tap(recoverIdentity);
        await tester.pumpAndSettle();
        await tester.tap(_dialogAction('Abandonner cette rubrique'));
        await tester.pumpAndSettle();
        expect(identity.draft.title, 'Titre enregistré');
        expect(identity.blocked, isFalse);
        expect(identity.dirty, isFalse);
        expect(exporter.identityWrites, 0);
        await tester.ensureVisible(
          find.byKey(const ValueKey('project-settings-return')),
        );
        await tester.tap(find.byKey(const ValueKey('project-settings-return')));
        await tester.pumpAndSettle();
        identity.edit(title: '');
        await tester.pumpAndSettle();
        final diagnostic = find.byKey(
          const ValueKey('studio-failure-open-owner'),
        );
        await tester.ensureVisible(diagnostic);
        await tester.tap(diagnostic);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('project-settings-unavailable')),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('project-settings-return')),
        );
        await tester.tap(find.byKey(const ValueKey('project-settings-return')));
        await tester.pumpAndSettle();
        returned = tester.widget<StudioGameExportPage>(
          find.byType(StudioGameExportPage),
        );
        expect(returned.identity, same(identity));
        expect(exporter.failure!.owner, owner);
        expect(find.text('À corriger dans : ${owner.label}'), findsOneWidget);
        expect(identity.draft.title, '');
        identity.edit(title: 'Titre conservé');
        exporter.failIdentitySave = true;
        final failed = returned.prepare();
        await tester.pumpAndSettle();
        await tester.tap(_dialogAction('Enregistrer puis exporter'));
        await tester.pumpAndSettle();
        expect(await failed, isFalse);
        expect(identity.dirty, isTrue);
        expect(identity.error, contains('Conflit identité conservé'));
        exporter.failIdentitySave = false;
        final retried = returned.prepare();
        await tester.pumpAndSettle();
        await tester.tap(_dialogAction('Enregistrer puis exporter'));
        await tester.pumpAndSettle();
        expect(await retried, isTrue);
        expect(identity.dirty, isFalse);
        expect(exporter.metadata!.title, 'Titre conservé');
        expect(exporter.identityWrites, 2);
        expect(maps.active, same(document));
        expect(port.fullReads, 0);
        home.navigate('map');
        await tester.pumpAndSettle();
        home.navigate('projectSettings');
        await tester.pumpAndSettle();
        expect(find.text('Retour à la carte'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'identity conflict recovery requires consent and retains the map draft',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final port = _Maps();
      final maps = MapWorkspaceController(scopedMapSession, port);
      final home = StudioHomeNavigation();
      final exporter = _Export(StudioFailureOwner.general);
      addTearDown(maps.dispose);
      addTearDown(home.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: MapWorkspaceScreen(
            controller: maps,
            home: home,
            loadVisuals: (_, _) async => WorkspaceTestVisuals(),
            runtimeBuilder: (_, _, _) => const SizedBox(),
            gameExport: exporter,
            gameExportPicker: (_) async => null,
            onClose: () async {},
            registerExitGuard: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final document = maps.active!;
      document.commit(document.current.copyWith(name: 'Carte à conserver'));
      final history = document.undoToken;
      home.navigate('gameExport');
      await tester.pumpAndSettle();
      final page = tester.widget<StudioGameExportPage>(
        find.byType(StudioGameExportPage),
      );
      final identity = page.identity!;
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
      await tester.pumpAndSettle();
      final edit = find.byKey(const ValueKey('export-edit-identity'));
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      final recover = find.byKey(
        const ValueKey('settings-recover-project-general'),
      );
      await tester.ensureVisible(recover);
      await tester.tap(recover);
      await tester.pumpAndSettle();
      expect(find.textContaining('Titre local'), findsWidgets);
      expect(find.textContaining('Titre enregistré ailleurs'), findsWidgets);
      await tester.tap(_dialogAction('Conserver le brouillon'));
      await tester.pumpAndSettle();
      expect(identity.conflict, same(conflict));
      expect(identity.draft.title, 'Titre local');
      await tester.tap(recover);
      await tester.pumpAndSettle();
      await tester.tap(_dialogAction('Abandonner cette rubrique'));
      await tester.pumpAndSettle();
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
      await tester.ensureVisible(
        find.byKey(const ValueKey('project-settings-return')),
      );
      await tester.tap(find.byKey(const ValueKey('project-settings-return')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<StudioGameExportPage>(find.byType(StudioGameExportPage))
            .identity,
        same(identity),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Finder _dialogAction(String label) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(label));

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
