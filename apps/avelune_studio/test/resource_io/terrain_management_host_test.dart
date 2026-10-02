import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_editor_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu5_terrain_host.dart';

void main() {
  testWidgets('published path rename persists without publishing draft rules', (
    tester,
  ) async {
    final host = await openUwU5TerrainHost(tester, savedDraft: true);
    final before = await host.reopen();
    final preset = before.smartTileCatalog.presets.single;
    await host.family(ResourceKind.terrains);
    await host.action('terrains:${preset.id}', 'Renommer le terrain…');
    await host.enter('resource-terrain-name', 'Sentier des étoiles');
    await host.tap('resource-management-save');
    final after = await host.reopen();
    expect(after.smartTileCatalog.presets.single.name, 'Sentier des étoiles');
    expect(after.smartTileCatalog.presets.single.rules, preset.rules);
    expect(after.smartTileCatalog.drafts.single.name, 'Sentier des étoiles');
    expect(
      after.smartTileCatalog.drafts.single.rules,
      before.smartTileCatalog.drafts.single.rules,
    );
    expect(after.tilesets, before.tilesets);
    expect(find.textContaining('Modifications non publiées'), findsWidgets);
    await tester.tap(
      find.text('Reprendre le brouillon : Sentier des étoiles').last,
    );
    await pumpIo(tester);
    await tester.tap(find.text('Publier et peindre').last);
    await pumpIo(tester, frames: 20);
    final republished = await host.reopen();
    expect(
      republished.smartTileCatalog.presets.single.name,
      'Sentier des étoiles',
    );
    expect(
      republished.smartTileCatalog.presets.single.rules,
      after.smartTileCatalog.drafts.single.rules,
    );
    expect(republished.smartTileCatalog.drafts, isEmpty);
  });

  testWidgets('published path duplicates into independent saved preparation', (
    tester,
  ) async {
    final host = await openUwU5TerrainHost(tester);
    final before = await host.reopen();
    final preset = before.smartTileCatalog.presets.single;
    await host.family(ResourceKind.terrains);
    await host.action('terrains:${preset.id}', 'Dupliquer le terrain…');
    expect(find.textContaining('Version publiée'), findsWidgets);
    await host.enter('resource-terrain-name', 'Chemin indépendant');
    await host.tap('resource-management-save');
    final after = await host.reopen();
    expect(after.smartTileCatalog.presets, before.smartTileCatalog.presets);
    final draft = after.smartTileCatalog.drafts.single;
    expect(draft.name, 'Chemin indépendant');
    expect(draft.targetPresetId, isNot(preset.id));
    expect(draft.sourcePresetId, isNull);
    await pumpIo(tester, frames: 12);
    expect(terrainDraftCompatibilityProblem(after, draft), isNull);
    expect(find.byType(TerrainEditorScreen), findsOneWidget);
  });

  testWidgets('draft withdrawal preserves published terrain and source', (
    tester,
  ) async {
    final host = await openUwU5TerrainHost(tester, savedDraft: true);
    final before = await host.reopen();
    await host.family(ResourceKind.terrains);
    await host.tap('terrain-draft-actions-draft-path-draft');
    await tester.tap(find.text('Supprimer le brouillon…').last);
    await pumpIo(tester);
    expect(find.textContaining('publication reste'), findsOneWidget);
    await host.tap('resource-terrain-confirm');
    await host.tap('resource-management-save');
    final after = await host.reopen();
    expect(after.smartTileCatalog.drafts, isEmpty);
    expect(after.smartTileCatalog.presets, before.smartTileCatalog.presets);
    expect(after.tilesets, before.tilesets);
  });

  testWidgets('painted path deletion is refused through real preparation', (
    tester,
  ) async {
    final host = await openUwU5TerrainHost(tester, used: true);
    final before = await host.reopen();
    await host.family(ResourceKind.terrains);
    await host.action(
      'terrains:${before.smartTileCatalog.presets.single.id}',
      'Supprimer le terrain…',
    );
    await pumpIo(tester, frames: 20);
    expect(
      find.byKey(const ValueKey('resource-terrain-refusal')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('resource-management-save')),
          )
          .onPressed,
      isNull,
    );
    await host.tap('resource-management-cancel');
    expect((await host.reopen()).smartTileCatalog, before.smartTileCatalog);
  });
}
