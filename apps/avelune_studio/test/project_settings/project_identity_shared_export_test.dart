import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/project_settings/application/project_identity_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/presentation/features/game_export/studio_game_export_page.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_actions.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

import '../support/m3_story_fixture.dart';

void main() {
  late M3StoryFixture source;
  late Directory root;
  late StudioGameExportController export;
  late ProjectIdentityController identity;

  setUp(() async {
    source = await M3StoryFixture.create();
    root = source.directory;
    export = StudioGameExportController(
      projectRoot: root,
      projectName: 'Échos de Johto',
    );
    identity = ProjectIdentityController(port: export);
    await identity.open();
  });

  tearDown(() async {
    identity.dispose();
    export.dispose();
    await root.delete(recursive: true);
  });

  GamePackageExportProfileStore store() =>
      GamePackageExportProfileStore(projectRoot: root);

  test(
    'a saved title change reaches export with the same game identifier',
    () async {
      expect(identity.exists, isFalse);
      final gameId = identity.draft.gameId;
      expect(gameId, startsWith('games.avelune.'));
      expect(await identity.save(), isTrue);
      expect(identity.exists, isTrue);

      identity.edit(title: 'Échos de Johto — Édition hiver');
      expect(identity.dirty, isTrue);
      expect(await identity.save(), isTrue);
      expect(identity.dirty, isFalse);

      final persisted = (await store().read()).profile!;
      expect(persisted.title, 'Échos de Johto — Édition hiver');
      expect(persisted.gameId, gameId);
      expect(identity.exportMetadata.title, 'Échos de Johto — Édition hiver');
      expect(identity.exportMetadata.gameId, gameId);
    },
  );

  test(
    'a default language missing from the available ones blocks saving',
    () async {
      expect(await identity.save(), isTrue);
      final before = await store().read();
      identity.edit(locale: 'en', locales: 'fr');
      expect(identity.fieldErrors[StudioGameIdentityField.locale], isNotNull);
      expect(identity.fieldErrors[StudioGameIdentityField.title], isNull);
      expect(await identity.save(), isFalse);
      expect((await store().read()).profileRevision, before.profileRevision);
      identity.edit(locales: 'fr, en');
      expect(identity.fieldErrors, isEmpty);
      expect(await identity.save(), isTrue);
      expect((await store().read()).profile!.supportedLocales, ['fr', 'en']);
    },
  );

  test(
    'an external profile change blocks a stale save and keeps both versions',
    () async {
      expect(await identity.save(), isTrue);
      final current = await store().read();
      await store().save(
        current.profile!.copyWith(title: 'Version externe'),
        expectedProfileRevision: current.profileRevision,
        expectedContextRevision: current.contextRevision,
      );
      identity.edit(title: 'Mon brouillon');

      expect(await identity.save(), isFalse);

      expect(identity.conflict, isNotNull);
      expect(identity.conflict!.metadata!.title, 'Version externe');
      expect(identity.draft.title, 'Mon brouillon');
      expect((await store().read()).profile!.title, 'Version externe');
      expect(identity.error, isNotNull);

      identity.reloadExternal();
      expect(identity.draft.title, 'Version externe');
      expect(identity.conflict, isNull);
      expect(identity.dirty, isFalse);
    },
  );

  test(
    'saving the identity keeps the profile fields it does not edit',
    () async {
      final initial = GamePackageExportProfile(
        gameId: 'games.avelune.echos',
        gameVersion: '1.0.0',
        title: 'Échos',
        authorName: 'Équipe',
        defaultLocale: 'fr',
        supportedLocales: const ['fr'],
        description: 'Une aventure.',
        accentColor: '#336699',
      );
      final snapshot = await store().validate(initial);
      await store().save(
        initial,
        expectedProfileRevision: snapshot.profileRevision,
        expectedContextRevision: snapshot.contextRevision,
      );
      await identity.open();
      identity.edit(version: '1.1.0');
      expect(await identity.save(), isTrue);
      final persisted = (await store().read()).profile!;
      expect(persisted.gameVersion, '1.1.0');
      expect(persisted.description, 'Une aventure.');
      expect(persisted.accentColor, '#336699');
      expect(persisted.gameId, 'games.avelune.echos');
    },
  );

  testWidgets('the export page shows the identity owned by General', (
    tester,
  ) async {
    await tester.runAsync(() async {
      expect(await identity.save(), isTrue);
      identity.edit(title: 'Titre partagé');
      expect(await identity.save(), isTrue);
    });
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StudioGameExportPage(
            controller: export,
            identity: identity,
            onEditIdentity: () => opened++,
            prepare: () async => true,
            hasPendingChanges: () => false,
            isCurrentProject: () => true,
            pickFile: (_) async => null,
          ),
        ),
      ),
    );
    for (
      var i = 0;
      i < 80 && find.text('Titre partagé').evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Titre partagé'), findsWidgets);
    expect(find.text('Titre du jeu'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('export-edit-identity')));
    expect(opened, 1);
    await tester.pumpWidget(const SizedBox());
  });

  test('General saves through the identity draft and guards closing', () async {
    final visuals = ProjectVisualsController(
      session: source.session,
      port: source.maps,
    );
    addTearDown(visuals.dispose);
    final session = ProjectSettingsSessionController(
      projectVisuals: visuals,
      general: IdentitySettingsDraft(identity),
    );
    addTearDown(session.dispose);
    final workspace = MapWorkspaceController(source.session, source.maps);
    addTearDown(workspace.dispose);
    expect(session.canSave(ProjectSettingsSection.general), isTrue);
    expect(session.isDirty(ProjectSettingsSection.general), isFalse);
    expect(await session.save(ProjectSettingsSection.general), isTrue);
    identity.edit(author: 'Studio Avelune');
    expect(session.isDirty(ProjectSettingsSection.general), isTrue);
    final actions = WorkspaceActions(
      controller: workspace,
      context: () => throw UnimplementedError(),
      mounted: () => true,
      changed: () {},
      resources: () => null,
      narrative: () => null,
      projectIdentity: () => identity,
      runtimeBuilder: (_, _, _) => throw UnimplementedError(),
    );
    expect(actions.hasCatalogDependencyDraft, isTrue);
    expect(await session.save(ProjectSettingsSection.general), isTrue);
    expect(actions.hasCatalogDependencyDraft, isFalse);
    expect((await store().read()).profile!.authorName, 'Studio Avelune');
  });
}
